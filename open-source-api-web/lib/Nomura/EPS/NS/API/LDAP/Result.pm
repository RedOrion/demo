package Nomura::EPS::NS::API::LDAP::Result;

use namespace::autoclean;
use Moose;
use Carp;
use Data::Compare;
use Data::Dumper;
use Moose::Util qw(find_meta);

use Nomura::EPS::NS::API::Exception qw(throw_api_error);
use Nomura::EPS::NS::API::Constants qw(:API__ERROR);

has 'dn'                => (is => 'ro', builder     => '_build_dn');
has 'result_set'        => (is => 'rw', isa         => 'Nomura::EPS::NS::API::LDAP::ResultSet');
has 'clone'             => (is => 'rw', init_arg    => undef);

sub BUILD {
    my ($self) = @_;

    $self->clone($self->create_clone);
}

# Insert the entry into the directory
#
sub insert {
    my ($self) = @_;

    my $attrs;
    push @$attrs, 'objectClass' => $self->result_set->object_classes;
    my $name_map = $self->result_set->name_map;

    for my $attr (keys %{$name_map}) {

        my $attr_type = $self->_attribute_type($attr);

        # If the moose attribute type is defined as an 'ArrayRef' then we want to
        # check if the list is defined and has a length, otherwise in scalar context if it is defined
        #
        if ($attr_type =~ m/^(Maybe\[)?ArrayRef/) {
            if (defined $self->$attr && @{$self->$attr} > 0 ) {
                push @$attrs, $name_map->{$attr} => $self->$attr;
            }
        }
        else {
            if (defined $self->$attr) {
                push @$attrs, $name_map->{$attr} => $self->$attr;
            }
        }
    }
    my $mesg = $self->result_set->connection->ldap->add($self->dn, attrs => $attrs);

    if ($mesg->{resultCode} != 0) {
        throw_api_error
            errors  => [{
                message => "Cannot insert the record",
                code    => $API__ERROR__CANNOT_CREATE_LDAP_RECORD,
                host    => $self->result_set->connection->host,
            }],
        ;
    }
    return $self;
}

# Update an entry in the directory
#   For all fields that are defined, a 'replace' operation will be performed
#   this will replace existing entries or, if no entry exists yet, will create one
#   For all fields that are set to undef a 'delete' operation will be performed.
#
#   For fields that support multiple values, if a list of values is provided then
#   all entries in LDAP will be replaced with the new list
#   If an empty list is provided then the entry will be deleted.
#
#   Attributes are written one-by-one so we can determine which attribute caused
#   the failure.
#
sub update {
    my ($self, $args) = @_;

    # First update any arguments passed to update
    for my $arg (keys %$args) {
        $self->$arg($args->{$arg});
    }

    my $name_map = $self->result_set->name_map;

    my @keys = sort keys %{$name_map};
    while (@keys) {
        my $key = shift @keys;

        if ($self->attribute_has_changed($key)) {
            my $ldap_key = $name_map->{$key};
            my @changes;

            if (defined $self->$key) {
                push @changes, 'replace' => [$ldap_key => $self->$key],
            }
            else {
                push @changes, 'delete' => [$ldap_key => []],
            }

            my $mesg = $self->result_set->connection->ldap->modify($self->dn, changes => \@changes);

            if ($mesg->{resultCode} != 0) {
                # Abort the update for this and all following attributes.
                # We have to update this, and the following attributes from the clone
                # to indicate the values they (still) have on the server.
                unshift(@keys, $key);
                while (@keys) {
                    my $key = shift @keys;
                    $self->_restore_attribute($key);
                }
                throw_api_error
                    errors  => [{
                        message         => "Cannot update the record",
                        code            => $API__ERROR__CANNOT_UPDATE_LDAP_FIELD,
                        attribute       => $key,
                        ldap_attribute  => $name_map->{$key},
                        host            => $self->result_set->connection->host,
                    }],
                ;
            }
        }
    }
    # update the clone to represent the values now held on the server
    $self->clone($self->create_clone);
    return $self;
}

# Delete the entry from the directory
#
sub delete {
    my ($self) = @_;

    my $mesg = $self->result_set->connection->ldap->delete($self->dn);

    if ($mesg->{resultCode} != 0) {
        throw_api_error
            errors  => [{
                message => "Cannot delete the record, perhaps it is a permission problem?",
                code    => $API__ERROR__CANNOT_DELETE_LDAP_RECORD,
                host    => $self->result_set->connection->host,
            }],
        ;
    }
    return;
}

# Rollback changes to where they were
#   Rollback consists of exchanging the attribute values with their clone values
#   and then performing an update
#   the clone is then updated from the attributes to represent the values on the server
#
sub rollback {
    my ($self) = @_;

    my %attrs;
    my $name_map = $self->result_set->name_map;

    # $new_clone will hold the current attribute values
    my $new_clone = $self->create_clone;

    # Restore the current attribute values from the current clone.
    for my $attr (keys %{$name_map}) {
        $self->_restore_attribute($attr);
    }
    $self->clone($new_clone);
    eval {
        $self->update;
    };
    if (my $e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        throw_api_error
            errors => [{
                message => "Cannot rollback the changes",
                code    => $API__ERROR__CANNOT_ROLLBACK_ERROR,
            }],
        ;
    }

    return $self;
}
# determine if an attribute has changed by comparing it against it's clone
# counterpart
# Use Data::Compare to compare the two structures
#

sub attribute_has_changed {
    my ($self, $attr) = @_;

    # Compare returns 0 if the structures differ

    if ( Compare($self->$attr, $self->clone->$attr) ) {
        return;
    }
    return 1;
}

# Convenience method.
#
sub attribute_has_not_changed {
    my ($self, $attr) = @_;

    return ! $self->attribute_has_changed($attr);
}

# clone an attribute
#
sub _clone_attribute {
    my ($self, $attr) = @_;

    my $attr_type = $self->_attribute_type($attr);

    # If the moose attribute type is defined as an 'ArrayRef' then we want to
    # make a shallow copy. If it is a simple scalar and is defined we make a scalar copy.
    #
    if ($attr_type =~ m/^(Maybe\[)?ArrayRef/) {
        if (defined $self->$attr && @{$self->$attr} > 0 ) {
            # de-reference it to make a shallow copy
            $self->clone->$attr([@{$self->$attr}]);
        }
    }
    else {
        if (defined $self->$attr) {
            $self->clone->$attr($self->$attr);
        }
    }
}

# Create a clone
#   we can't use _clone_attribute because we don't know which attributes are required
#   on creating a new object
#
sub create_clone {
    my ($self) = @_;

    my %attrs;
    $attrs{objectClass} = [@{$self->result_set->object_classes}];
    my $name_map = $self->result_set->name_map;

    for my $attr (keys %{$name_map}) {
        my $attr_type = $self->_attribute_type($attr);

        # If the moose attribute type is defined as an 'ArrayRef' then we want to
        # make a shallow copy. If it is a simple scalar and is defined we make a scalar copy.
        #
        if ($attr_type =~ m/^(Maybe\[)?ArrayRef/) {
            if (defined $self->$attr && @{$self->$attr} > 0 ) {
                # de-reference it to make a shallow copy
                $attrs{$attr} = [@{$self->$attr}];
            }
        }
        else {
            if (defined $self->$attr) {
                $attrs{$attr} = $self->$attr;
            }
        }
    }
    return $self->meta->clone_object($self, %attrs);
}

# Build the dn
#
sub _build_dn {
    my ($self) = @_;

    my $result_set      = $self->result_set;
    my $result_set_key  = $result_set->key;
    my $result_set_value;

    # find the fieldname corresponding to the key
    my $name_map = $result_set->name_map;
KEY:
    for my $key (keys %{$name_map}) {
        if ($name_map->{$key} eq $result_set_key) {
            $result_set_value = $self->$key;
            last KEY;
        }
    }

    my $dn = "$result_set_key=$result_set_value,".$result_set->base;

    return $dn;
}

# Obtain the attribute type
#
sub _attribute_type {
    my ($self, $attr) = @_;

    my $class = ref $self;

    # Do some Moose Meta Magic to get the attribute type from the Result class
    my $attr_type = find_meta($class)->get_attribute($attr)->type_constraint->name;

    return $attr_type;
}

# Restore an attribute from it's clone
#   Note, we can't restore read-only attributes.
sub _restore_attribute {
    my ($self, $attr) = @_;

    my $attr_type = $self->_attribute_type($attr);

    # If the moose attribute type is defined as an 'ArrayRef' then we want to
    # make a shallow copy. If it is a simple scalar and is defined we make a scalar copy.
    #
    # Catch any errors due to trying to write to read-only attributes
    eval {
        if ($attr_type =~ m/^(Maybe\[)?ArrayRef/) {
            if (defined $self->clone->$attr && @{$self->clone->$attr} > 0 ) {
                $self->$attr([@{$self->clone->$attr}]);
            }
        }
        else {
            $self->$attr($self->clone->$attr);
        }
    };
    # and just ignore them.
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::Result - Base class for an LDAP Result

=head1 SYNOPSIS

    package Nomura::EPS::NS::API::LDAP::NCD::Result::Group;

    use Moose;

    extends 'Nomura::EPS::NS::API::LDAP::Result';

    # Required attributes
    has 'group_name'        => (is => 'ro', isa => 'Str', required => 1);
    has 'gid_number'        => (is => 'rw', isa => 'Int', required => 1);

    # Optional attributes
    has 'description'       => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
    has 'member_uids'       => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
    has 'user_password'     => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');

    no Moose;
    __PACKAGE__->meta->make_immutable;

    1;

=head1 DESCRIPTION

Creates a class based on an LDAP entry. See also X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm>

A Result class represents a single entry from LDAP

=head1 ATTRIBUTES

Attributes are defined in the standard Moose manner. How they are defined depends upon the LDAP schema.

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
L<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm>

    my $group = Nomura::EPS::NS::API::LDAP::NCD::Result::Group->new({
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

Inserts an entry (created with B<new>) into LDAP.

    $group->insert;

It throws an exception if the insert fails.

=head2 update

Having created an object and made local modifications, the object can be written back to LDAP

    # read the group and make local changes
    $group = $group_rs->find('asiacct');
    push @{$group->member_uids}, 'docherti';
    $group->description(['asia cct group']);

    # commit the changes to LDAP
    $group->update;

The update can also take changes to attributes

    $group->update({
        member_uids     => [qw(one two three)],
        gid_number      => 777444333,
    });

These changes will be applied immediately before the update to LDAP

If any attribute cannot be written to LDAP then an exception is thrown. See the notes on
partial updates and rollback below for more details.

=head2 delete

Delete the entry from LDAP

    $group = $group_rs->find('old_group');

    # delete the group from LDAP
    $group->delete;

If the group was not able to be deleted then an exception is thrown

=head2 rollback

In the event that an exception is thrown during an B<update> then LDAP may have been
left in an incomplete state (since LDAP does not support transactions).

For example, if an attempt was made to update a group, where all attributes have been
altered, then attributes B<gid_number> may have successfully been updated, but then the
update failed on the B<member_uids>. In this case the LDAP record is in an incomplete state.

The rollback method attempts to restore the entry on LDAP back to its original value by
overwriting the modified attributes with their original values.

=head2 ACCESSORS

Accessors are used in the normal Moose manner.

    # read an accessor
    print "Group name is ". $group->group_name ."\n";

    # change an accessor
    $group->gid_number(987654321);

    # change all values in a multi-value attribute
    $group->member_uids(qw[qw(fee fi fo fum)]);

    # change a single value in a multi-value attribute
    my $member_uids = $group->member_uids;
    @{$member_uids}[1] = 'barny';

=head2 partial updates

When updating an LDAP entry, the attributes are updated individually according to the following rules.

=over 4

=item * attributes are updated in alphabetical order

=item * only attributes that have been changed (since the entry was read or created) are written

=item * the first attribute that fails to update will terminate all futher updates

=item * an exception is raised (see below) that indicates which attribute failed to update

=item * the attribute that failed to write, and all subsequent attributes, are reverted back to their original value

=back

The result of these operations means that in the event of an exception the object in memory should faithfully
represent the current state of the entry on LDAP. i.e. some attributes updated and some at their original value.

The normal action to take on such an exception is to issue a B<rollback> command to try and restore the record
back to the original state.

Note, although unlikely, it is possible for the rollback itself to throw an exception. What you do then is
anybodies guess!

=head2 exceptions

Some methods, where indicated, throw exceptions when an error occurs. You can handle these exceptions
as follows

    use Exception::Class;
    ...
    # try
    eval {
        $group->update({gid_number => 12345});
    };

    # catch
    if (my $e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        carp "Failed to update group record, reason " .$e->error
            ." error code " .$e->code
            ." failure on attribute ".$e->attribute
            ." ldap attribute ".$e->ldap_attribute;
        # handle the error
        $group->rollback;
    }

B<error> is a human readable version of the reason why the error occurred, B<code> is a machine
readable version, an integer, B<attribute> (e.g. 'gid_number') will indicate which attribute of all those being updated
failed, B<ldap_attribute> (e.g. 'gidNumber') is the name of the attribute as known by the LDAP server, B<ldap_server> is
the hostname of the ldap server (e.g. 'tl0067.lehman.com')

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
