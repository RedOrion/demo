package Nomura::EPS::NS::API::Middleware::Result;

use Moose;
use Carp;
use Data::Dumper;
use Log::Log4perl;

use Nomura::EPS::NS::API::Exception qw(throw_api_error);
use Nomura::EPS::NS::API::Constants qw(:API__ERROR);

has 'resultset'         => (is => 'ro', isa => 'Nomura::EPS::NS::API::Middleware::ResultSet', required => 1);
has 'nonce'             => (is => 'rw', isa => 'Maybe[Str]');

# Delete a record.
#
sub delete {
    my ($self) = @_;

    my $log = Log::Log4perl->get_logger(__PACKAGE__."delete");

    my $namespace   = ref $self;
    $namespace      =~ s/.*::Result:://;

    my $attr        = $self->resultset->attr;
    my %write_to    = %{$attr->{write_to}};
    my $key         = $attr->{key};
    my $original    = $self->resultset->find($self->$key);
    if (not $self->nonce) {
        $log->error("missing nonce");
        throw_api_error
            errors  => [{
                message => "Delete failed. Missing nonce",
                code    => $API__ERROR__MISSING_NONCE,
            }],
        ;
    }
    if ($original->nonce ne $self->nonce) {
        $log->error("changed nonce original=[".$original->nonce."] new=[".$self->nonce."]");
        throw_api_error
            errors  => [{
                message => "Delete failed. Nonce has changed or was not supplied",
                code    => $API__ERROR__CHANGED_NONCE,
            }],
        ;
    }

    for my $server_name (sort keys %write_to) {
        my $object = $self->resultset->middleware->$server_name->resultset($namespace)->find($self->$key);

        if ( $object ) {
            $object->delete;
        }
    }
    return;
}

# Insert a record.
#
sub insert {
    my ($self) = @_;

    my $resultset   = $self->resultset;
    my %write_to    = %{$resultset->attr->{write_to}};
    my $key         = $resultset->attr->{key};

    my $namespace   = ref $self;
    $namespace      =~ s/.*::Result:://;

    my @server_rollbacks;
    my $object;

    # try

    eval {
SERVER:
        for my $server_name (sort keys %write_to) {
            # Get the attributes we are going to write
            my $params;
            for my $attr (@{$write_to{$server_name}}) {
                if (defined $self->$attr) {
                    $params->{$attr} = $self->$attr;
                }
            }
            # Don't create an entry if we have no params
            next SERVER if not keys %$params;

            # We always write the key
            $params->{$key} = $self->$key;

            $object = $self->resultset->middleware->$server_name->resultset($namespace)->create($params);
            push @server_rollbacks, $object;
        }
    };
    # catch
    my $e;
    my $do_rollback;

    my @errors = ();

    if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        @errors = @{$e->errors};
        $do_rollback    = 1;
    } elsif ($e = Exception::Class->caught()) {
        @errors = (
            message     => "Could not insert a record, for an unknown reason $e",
            code        => $API__ERROR__GENERAL_ERROR,
        );
        $do_rollback    = 1;
    }
    if ($do_rollback) {

        # TRY
        eval {
            for my $object (@server_rollbacks) {
                $object->delete;
            }
        };

        # CATCH
        if ($e = Exception::Class->caught()) {
            push @errors, {
                message     => 'Failed to rollback errors',
                code        => $API__ERROR__CANNOT_ROLLBACK_ERROR,
            };
        }

        throw_api_error
            errors  => \@errors
        ;
    }
    return $object;
}

# Update a record.
#   First of all read the original record and check the nonce to ensure that
#       (a) the record has not changed
#       (b) that the caller has obtained the record by means of a find operation
#   Update each 'write_to' attribute
#   Update each backend system
#   In the event of an error, roll back all changes made to all backend systems and report the error
#   If there is no error, update the nonce
#
sub update {
    my ($self, $args) = @_;

    # First update any arguments passed to update
    for my $arg (keys %$args) {
        $self->$arg($args->{$arg});
    }

    my $namespace = ref $self;
    $namespace =~ s/.*::Result:://;

    my $attr = $self->resultset->attr;
    my $key = $attr->{key};
    my $original = $self->resultset->find($self->$key);

    if ( ! $self->nonce ) {
        throw_api_error
            errors  => [{
                message     => "Update failed. Nonce was not supplied",
                code        => $API__ERROR__MISSING_NONCE,
            }],
        ;
    }
    elsif ( $original->nonce ne $self->nonce) {
        throw_api_error
            errors  => [{
                message     => "Update failed. Nonce has changed, original=[".$original->nonce."] new=[".$self->nonce."]",
                code        => $API__ERROR__CHANGED_NONCE,
            }],
        ;
    }
    my %write_to = %{$self->resultset->attr->{write_to}};

    my %object_to;
    my %attr_value_of;
    my @server_rollbacks;
    my $object;

    # try
    eval {
        for my $server_name (sort keys %write_to) {
            $object = undef;
            my $pre_update_obj = $self->resultset->middleware->$server_name->resultset($namespace)->find($self->$key);

            if (! $pre_update_obj ) {
                throw_api_error
                    errors  => [{
                        message => "Update failed. Cannot find the $namespace object on server $server_name",
                        code    => $API__ERROR__CANNOT_FIND_OBJECT,
                        host    => $server_name,
                    }],
                ;
            }
            my $rollback_object = $pre_update_obj->create_clone;

            for my $attr (@{$write_to{$server_name}}) {
                $pre_update_obj->$attr($self->$attr);
            }

            # Only define $object just before we update it so as not to attempt a rollback
            # on something we have not yet updated.

            $object = $pre_update_obj;
            $object->update;

            push @server_rollbacks, $rollback_object;
        }
    };
    # catch
    my $e;
    my $do_rollback;

    my @errors = ();

    if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        @errors = @{$e->errors};
        $do_rollback    = 1;
    } elsif ($e = Exception::Class->caught()) {
        @errors = (
            message     => "Could not update a record, for an unknown reason $e",
            code        => $API__ERROR__GENERAL_ERROR,
        );
        $do_rollback    = 1;
    }

    if ($do_rollback) {
        # Rollback the object that caused the problem,
        # and all previous (successful) updates on other servers

        # TRY
        eval {
            for my $server_rollback (@server_rollbacks) {
                $server_rollback->rollback;
            }
            if ($object) {
                $object->rollback;
            }
        };

        # CATCH
        if ($e = Exception::Class->caught()) {
            push @errors, {
                message     => 'Failed to rollback errors',
                code        => $API__ERROR__CANNOT_ROLLBACK_ERROR,
            };
        }

        throw_api_error
            errors  => \@errors
        ;
    }
    return $self;
}

# Flatten a record so it can be displayed in a view.
#
sub flatten {
    my ($self, $base_url) = @_;

    my $log = Log::Log4perl->get_logger("Nomura::EPS::NS::API::Middleware::Result");

    my $flatten_ref;

    my $namespace = ref $self;
    ($namespace) = $namespace =~ /::Result::(.*)$/;
    $namespace = lc $namespace;

    # search terms are those which are read from NCD
    my $read_from   = $self->resultset->attr->{read_from};
    my $key         = $self->resultset->attr->{key};
    my @all_attribs;
    for my $key (keys %{$read_from}) {
        push @all_attribs, @{$read_from->{$key}};
    }
    # add the nonce
    if (defined $self->nonce) {
        $flatten_ref->{nonce} = $self->nonce;
    }

    for my $attr (@all_attribs) {
        $flatten_ref->{data}{$attr}= $self->$attr;
    }

    $log->debug("base_url=[$base_url] namespace=[$namespace] key=[$key]");
    $flatten_ref->{find_url} = "$base_url$namespace/".$self->$key;

    return $flatten_ref;
}



__PACKAGE__->meta->make_immutable;

1;


=head1 NAME

Nomura::EPS::NS::API::Middleware::Result - Base class for a Middleware Result

=head1 SYNOPSIS

    package Nomura::EPS::NS::API::Middleware::Result::Console;

    use Moose;
    use Carp;

    extends 'Nomura::EPS::NS::API::Middleware::Result';

    has 'hostname'          => (is => 'ro', isa => 'Str', required => 1);
    has 'terminal_server'   => (is => 'rw', isa => 'Maybe[Str]');
    has 'terminal_port'     => (is => 'rw', isa => 'Maybe[Int]');
    has 'admin_port'        => (is => 'rw', isa => 'Maybe[Int]');

    __PACKAGE__->meta->make_immutable;

    1;

=head1 DESCRIPTION

Creates a Middleware Result class which represents a single entry from the backend LDAP
servers.

The Middleware potentially obtains attributes from different back-end LDAP servers and
when updating it can update several LDAP servers with the data.

=head1 ATTRIBUTES

Attributes are defined in the standard Moose manner.

=over

=item * B<< required => 1 >> fields which are required when the object is created.

=item * B<< is => 'ro' >> attributes that are Read Only

=item * B<< is => 'rw' >> all other attributes will be Read Write

=item * B<< isa => 'Str' >> for attributes defined as strings

=item * B<< isa => 'Int' >> for attributes defined as integers

=item * B<< isa => 'ArrayRef[Str]' >> or B<< isa => 'ArrayRef[Int]' >> for multi value fields

=item * B<< isa => 'Maybe[Int]' >> or B<< isa => 'Maybe[ArrayRef[Int]]' >> for fields which are not required (may be left blank)

=back


=head1 METHODS

=head2 new

This creates a B<new> instance, but does not insert the instance to LDAP. To create a new instance
and immediately insert it into LDAP use the B<create> method inherited from
X<lib/Nomura/EPS/NS/API/Middleware/ResultSet.pm>

A B<create> is equivalent to a B<new> followed by an B<insert>

    my $group = Nomura::EPS::NS::API::Middleware::Result::Group->new({
        group_name      => 'new_group',
        gid_number      => 1234567,
        member_uids     => [qw(docherti smithj)],
        description     => ['short description'],
    })

Note that any multi-valued fields (such as B<description> and B<member_uids>) must be specified
as an array ref, even if they only contain one value. This may change in a later release.

Returns the object or throws an exception if the object could not be created (due to constraint
violations for example).

=head2 insert

Insert a new entry into the LDAP system

    $group->insert;

In the event of an error it throws an exception, so the call should be part of an eval block
to catch the error. The exception creates a X<lib/Nomura/EPS/NS/API/Exception.pm> object.

Otherwise it returns the original object.

In the event of an exception, the middleware will attempt to roll-back any changes made to the
back end LDAP servers. For example, if an B<insert> to NCD succeeded, but a following B<insert>
to GCD failed then the NCD insert will be rolled back (by doing a B<delete> on the inserted record).

=head2 update

Update the LDAP server(s) with the content of the record.

    $group->gid_number(98765432);
    $group->member_uids(['rubbleb']);
    $group->update;

    # this is entirely equivalent to
    $group->update({
        gid_number  => 98765432,
        member_uids => ['rubbleb'],
    });

Only attributes which have changed since the record was read will be written back to LDAP.
Attributes are written one at a time to each LDAP server, even when a single write could
update all attributes at once. This allows the back-end system to report which
attribute (if any) caused an exception (due for example to access control issues) which could
not be done if all attributes were written at the same time.

In the event of an error it throws an exception, so the call should be part of an eval block
to catch the error. The exception creates a X<lib/Nomura/EPS/NS/API/Exception.pm> object which
may indicate, for example, which LDAP server, and which attribute caused the error.

In the event of an exception, the middleware will attempt to roll-back any changes made to the
back end LDAP servers. For example, if LDAP server was updated correctly, but GCD only had the
first attribute updated, then the roll-back will restore the whole of the NCD record and the
first attribute of the GCD attribute.

=head2 delete

Delete the record from the LDAP server(s).

    $group->delete;

This will delete the record from all LDAP servers.

In the event of an error an exception is created, but there is no option for a roll-back.

If, for example, the record is deleted from NCD but fails to delete on GCD then the
exception will report that GCD failed, but it will not be able to restore the record on NCD.

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
