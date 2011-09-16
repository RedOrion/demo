package Nomura::EPS::NS::API::Middleware::ResultSet;

use namespace::autoclean;
use Moose;
use Carp;
use Data::Dumper;
use Data::Compare;
use Digest::MD5 (qw(md5_base64));
use Log::Log4perl;

use Nomura::EPS::NS::API::Constants qw(:API__ERROR);

use Nomura::EPS::NS::API::Exception qw(throw_api_error);

has 'attr'          => (is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_attr');
has 'middleware'    => (is => 'ro', isa => 'Nomura::EPS::NS::API::Middleware', required => 1);

# Secret 'seed' to the nonce to reduce the chance that someone could create one
#
sub nonce {
    my ($self) = @_;

    return 'jabberwocky quark';
}

# Pre-validate input arguments
#
sub pre_validate_attributes {
    my ($self, $data) = @_;

    my $result_class    = ref $self;
    $result_class       =~ s/::ResultSet::/::Result::/;

    my $meta = $result_class->meta;

    my $errors;
    for my $attr (sort keys %$data) {
        my $meta_attr = $meta->find_attribute_by_name($attr);
        if ($meta_attr) {
            # Verify against its type constraint
            # TRY
            eval {
                $meta_attr->verify_against_type_constraint($data->{$attr});
            };
            if ($@) {
                push @$errors, {
                    message     => "Attribute does not meet the required type constraint",
                    code        => $API__ERROR__TYPE_CONSTRAINT,
                    attribute   => $attr,
                    constraint  => $meta_attr->type_constraint->name,
                    value       => $data->{$attr},
                };
            }
        }
    }
    if ($errors and scalar @$errors) {
        throw_api_error
            errors  => $errors,
        ;
    }
}

# Update (an existing record) or Create a new one
#
sub update_or_create {
    my ($self, $key, $data) = @_;

    my $key_attr = $self->attr->{key};
    my ($errors, $object, $e);

    # We don't need to catch the error, let it propagate up to the caller

    $object = $self->find($key);

    # Put the key into the data
    if (defined $data->{$key_attr} && ! Compare($data->{$key_attr}, $key)) {
        # Complain if the key value has been changed
        push @$errors, {
            message     => "You cannot modify the key of a record",
            code        => $API__ERROR__CANNOT_MODIFY_KEY,
            attribute   => $key_attr,
            value       => $key,
        };
    }

    $data->{$key_attr} = $key;

    if ($object) {
        # The object exists, so this is an update request
        # Ensure a nonce has been provided
        if ( ! $data->{nonce} ) {
            push @$errors, {
                message => "You cannot update an existing record without a valid nonce",
                code    => $API__ERROR__MISSING_NONCE,
            };
        }

        # write to each attribute in turn so we can report specific errors
        #
ATTR:
        for my $attr (keys %$data) {
            # Don't try to update attributes that have not changed
            next ATTR if Compare($data->{$attr}, $object->$attr);

            eval {
                $object->$attr($data->{$attr});
            };
            if (my $e = Exception::Class->caught()) {
                push @$errors, {
                    message     => "Cannot update attribute. It might be read-only.",
                    code        => $API__ERROR__CANNOT_UPDATE_FIELD,
                    attribute   => $attr,
                };
            }
        }

        if (not $errors) {
            # Only attempt to update if are no existing errors
            eval {
                $object->update;
            };
            if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
                push @$errors, {
                    message         => $e->error,
                    code            => $e->code,
                    host            => $e->host,
                    attribute       => $e->attribute,
                    ldap_attribute  => $e->ldap_attribute,
                };
            }
        }
    }
    else {

        # Ensure that all required fields are present.
        # TBD

        if (not $errors) {
            eval {
                $object = $self->create($data);
            };

            if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
                push @$errors, {
                    message => $e->error,
                    code    => $e->code,
                    host    => $e->host,
                };
            }
            elsif ($e = Exception::Class->caught()) {
                push @$errors, {
                    message => "Cannot create object.",
                    code    => 2001,
                };
            }
            elsif ($e = $@) {
                push @$errors, {
                    message => "Cannot create object. Unknown reason",
                    code    => 2001,
                };
            }
        }
        # QUESTION: If a field is not defined as 'Maybe' and is not 'required' can it be left undefined?

    }
    if ($errors) {
        throw_api_error
            errors  => $errors,
    }

    return $object;
}

# Create and insert an object
#
sub create {
    my ($self, $params) = @_;

    my $class       = ref $self;
    $class          =~ s/::ResultSet::/::Result::/;

    my $args = {%$params};
    $args->{resultset} = $self;

    my $object = $class->new($args);
    $object->insert;

    return $object;
}

# Create a nonce.
#
sub _create_nonce {
    my ($self, $nonce_values) = @_;

    # The nonce is just a concatination of the values of the object in a set order
    # then md5 hashed. If any value changes then the value of the md5 hash will change.
    # When updating a record we re-calculate the nonce from the back-end system comparing
    # it with the returned value. This prevents updates to records not correctly fetched
    # and prevents updates where the back-end has been changed (perhaps by another user).

    my $nonce = $self->nonce;
    for my $val (@$nonce_values) {
	# Check typeof 'ref'
        if (ref $val eq 'ARRAY') {
            for my $v (@$val) { 
	        $nonce .= '*'.$v;
	    }
	}
        elsif ( ref $val eq 'HASH') {
	    # TODO: Can the ref be of type HASH? Need to verify that.
            die "Hash ref encountered.";
        }
        else {
            $nonce .= '|'.$val;
        }
    }
    return md5_base64($nonce);
}

# Get the result class meta data
#
sub result_meta {
    my ($self) = @_;

    my $result_class    = ref $self;
    $result_class       =~ s/::ResultSet::/::Result::/;
    return $result_class->meta;
}

# Get the namespace for this object
#
sub namespace {
    my ($self) = @_;

    my $namespace = ref $self;
    $namespace =~ s/.*::ResultSet:://;
    return $namespace;
}

# Get a Result based on it's key
#
sub find {
    my ($self, $key) = @_;

    my $result_meta = $self->result_meta;

    my @nonce_values;

    my %read_from       = %{$self->attr->{read_from}};
    my $attr_value_of;
    my $found_on_ncd;
    my $found_on_other_server;

    my $result_class    = ref $self;
    $result_class       =~ s/::ResultSet::/::Result::/;

    # set default values for required fields
    $attr_value_of = $self->set_default_values;

    SERVER:
    for my $server_name (sort keys %read_from) {
        # Find the record from the LDAP resultset object for the server (e.g. 'ncd')
        # in class
        my $object = $self->middleware->$server_name->resultset($self->namespace)->find($key);

        next SERVER if ! $object;

        if ($server_name eq 'ncd') {
            $found_on_ncd = 1;
        }
        else {
            $found_on_other_server = $server_name;
        }

        for my $attr (@{$read_from{$server_name}}) {
            my $value = $object->$attr;

            $attr_value_of->{$attr} = $value;

            if (defined $value) {
                push @nonce_values, $value;
            }
        }
    }
    return if not ($found_on_ncd or $found_on_other_server);

    if ($found_on_other_server and not $found_on_ncd) {
        # if it is on other servers, but not on NCD then we throw an error
        throw_api_error
            errors  => [{
                message => "Find failed. Record is not on NCD but *is* on other servers.",
                code    => $API__ERROR__NOT_FOUND_ON_NCD,
                host    => $found_on_other_server,
            }],
        ;
    }

    $attr_value_of->{nonce}       = $self->_create_nonce(\@nonce_values);
    $attr_value_of->{resultset}   = $self;

    my $c   = ref $self;
    $c      =~ s/::ResultSet::/::Result::/;

    return $c->new($attr_value_of);
}

# Get the meta_data
#
sub meta_data {
    my ($self) = @_;

    my $meta_data = {
        search_terms    => [$self->get_search_terms],
        all_terms       => $self->get_all_terms,
        key             => $self->attr->{key},
    };
    return $meta_data;
}


# Get the search terms (just those from NCD)
#
sub get_search_terms {
    my ($self) = @_;

    my $log = Log::Log4perl->get_logger;
    $log->debug("################ GOT HERE #################\n");

    return sort @{$self->attr->{read_from}{ncd}};
}

# Get all the terms (not just those from NCD)
#
sub get_all_terms {
    my ($self) = @_;

    my $result_class    = ref $self;
    $result_class       =~ s/::ResultSet::/::Result::/;

    my $meta = $result_class->meta;

    my $terms;
    my $tooltips = $self->attr->{tooltips};
    for my $host (sort keys %{$self->attr->{read_from}}) {
        for my $attr (sort @{$self->attr->{read_from}{$host}}) {
            my $meta_attr   = $meta->find_attribute_by_name($attr);
            my $constraint  = 'unknown';
            if ($meta_attr) {
                $constraint = $meta_attr->type_constraint->name;
            }
            my $required    = $meta_attr->is_required ? 1 : 0;
            my $read_only   = defined $meta_attr->accessor ? 0 : 1;
            my $tooltip     = defined $tooltips->{$attr} ? $tooltips->{$attr} : '';
            $terms->{$attr} = {constraint => $constraint, required => $required, read_only => $read_only, tooltip => $tooltip};
        }
    }
    return $terms;
}

# Set default values for all required fields, this is so that if we
# search (on NCD) for records, but there are mandatory fields on another
# LDAP server (e.g. GCD) then this would prevent us from creating a
# record (due to the missing mandatory field). However, if we create
# dummy values (e.g. a blank string or the value zero) then the record
# can be created correctly.


sub set_default_values {
    my ($self, $ldap_object) = @_;
    my $attr_value_of = {};

    my $result_meta = $self->result_meta;
    my @attribs = $result_meta->get_attribute_list;
    for my $attrib (@attribs) {
        my $meta_attrib = $result_meta->get_attribute($attrib);
        if ($meta_attrib->is_required) {
            # Then we need to provide a default (that can be overwritten later)
            my $meta_name = $meta_attrib->type_constraint->name;
            my $value;
            if ($meta_name eq 'Int') {
                $value = 0;
            }
            elsif ($meta_name eq 'Str') {
                $value = '';
            }
            elsif ($meta_name eq 'ArrayRef[Int]') {
                $value = [];
            }
            elsif ($meta_name eq 'ArrayRef[Str]') {
                $value = [];
            }
            $attr_value_of->{$attrib} = $value;
        }
    }
    return $attr_value_of;
}

# Search for a set of values
#
sub search {
    my ($self, $args) = @_;

    # all search terms must come from the NCD, otherwise it is an exception
    for my $attr (keys %$args) {
        # exception if the search attribute is not on NCD
        if ( ! grep {$attr eq $_} $self->get_search_terms) {
            throw_api_error
                errors      => [{
                    message     => "Search failed. Attribute is not a valid search term",
                    code        => $API__ERROR__INVALID_ATTRIBUTE,
                    attribute   => $attr,
                }],
            ;
        }
    }

    my $objects = $self->middleware->ncd->resultset($self->namespace)->search($args);

    my @results;
    my %read_from       = %{$self->attr->{read_from}};

    # For each LDAP object found, create a Middleware object
    for my $object (@$objects) {

        # set default values for required fields
        my $attr_value_of = $self->set_default_values;

        for my $attr (@{$read_from{ncd}}) {
            $attr_value_of->{$attr} = $object->$attr;
        }

        $attr_value_of->{resultset}   = $self;

        my $c = ref $self;
        $c =~ s/::ResultSet::/::Result::/;

        push @results, $c->new($attr_value_of);
    }
    return \@results;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Nomura::EPS::NS::API::Middleware::ResultSet - Base class for a Middleware ResultSet

=head1 SYNOPSIS

    package Nomura::EPS::NS::API::Middleware::ResultSet::Console;

    use namespace::autoclean;
    use Moose;

    extends 'Nomura::EPS::NS::API::Middleware::ResultSet';

    sub _build_attr {
        return {
            key => 'hostname',
            read_from => {
                ncd => [qw(hostname terminal_server terminal_port)],
                gcd => [qw(admin_port)],
            },
            write_to => {
                ncd => [qw(hostname terminal_server terminal_port)],
                gcd => [qw(hostname terminal_server terminal_port admin_port)],
            },
        };
    };

    __PACKAGE__->meta->make_immutable;

    1;

=head1 DESCRIPTION

Creates a ResultSet class for a Middleware entry. See also X<lib/Nomura/EPS/NS/API/Middleware/Result.pm>

A ResultSet is the class used to fetch a set of results from LDAP.

=head1 ATTRIBUTES

The only attribute required is the the B<attr> attributue. This is created with the B<_build_attr> method
that must be included in your class (see the example in the Synopsis).

At the moment, B<_build_attr> is hard-coded, at some future date this information will be obtained from
a MySQL database so that it can be configured externally.

Attribute B<attr> is a hash consisting of the following parts.

=over 4

=item * B<key> is the attribute that is used in B<find> methods, the equivalent in database terms is
the primary key.

=item * B<read_from> specifies which server (ncd or gcd or others) each attribute should be obtained from.
All attributes should be specified once, and only once, in the B<read_from> section.

=item * B<write_to> specifies which server each attribute should be written to when a record is updated
or created. Attributes can appear in more than one server, for example if ncd is the primary source for
the data but the attribute needs to be updated in gcd as well.

=back

=head1 METHODS

=head2 new

You would not normally call B<new> directly on a ResultSet, the normal method of creating one would be as follows

    my $middleware = Nomura::EPS::NS::API::Middleware->new({
        ncd     => $ncd,
        gcd     => $gcd,
    });

    my $console_rs = $middleware->resultset('Console');

=head2 create

Create a B<Result> object, insert it into all LDAP directories and return the object.

    my $console = $console_rs->create({
        hostname        => 'london_calling',
        terminal_server => 'london_ts',
        terminal_port   => 2345,
        admin_port      => 45,
    });

In the event that a record cannot be created an exception will be thrown. Any changes made to the back-end
will be rolled-back so that the back-end servers should be left in the state they were in before the create
call was made.

=head2 find

Find a single entry based on its key

    $console = $console_rs->find('london_calling');

If the entry can be found, it is returned. Otherwise the method returns undef.

=head2 search

Search for entries that meet the search criteria.

    my $consoles = $console_rs->search({
        terminal_server => 'lon*',
        terminal_port   => 1234,
    });

    for my $console (@$consoles) {
        print "Found: host ".$console->hostname."\n";
    }

This example finds all consoles where the B<terminal_server> name begins with the string 'lon'
B<and> the terminal_port has the exact numeric value of 1234.

Wildcard endings are indicated by the asterix, otherwise the match is expected to be exact.

Note that if you search for multiple attributes the code carries out a logical B<and> on all these terms.
It is not possible at the moment to specify a logical B<or>.

Currently only a subset of the LDAP search criteria are supported. The B<wildcard> search using an asterix, e.g.
a search for '*smi*' will find any entry where substring 'smi' is anywhere in the string.

=head2 _create_nonce

Create nonce of the values of the object and then md5 hashed.

    $attr_value_of->{nonce}       = $self->_create_nonce(\@nonce_values);

If the value is a B<scalar> it is directly concatinated and md5 hashed.
If the value is B<ref to ARRAY>, it is iterated further and the B<scalars> are concatinated and md5 hashed.

The nonce is just a concatination of the values of the object in a set order then md5 hashed. If any value
changes then the value of the md5 hash will change. When updating a record we re-calculate the nonce from the
back-end system comparing it with the returned value. This prevents updates to records not correctly fetched
and prevents updates where the back-end has been changed (perhaps by another user).

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut


