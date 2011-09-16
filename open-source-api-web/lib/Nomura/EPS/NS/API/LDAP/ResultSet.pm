package Nomura::EPS::NS::API::LDAP::ResultSet;

use namespace::autoclean;
use Moose;
use Carp;
use Data::Dumper;
use Moose::Util qw(find_meta);

has 'name_map'          => (is => 'ro',                         lazy => 1, builder => '_build_name_map');
has 'base'              => (is => 'rw', isa => 'Str',           lazy => 1, builder => '_build_base');
has 'object_classes'    => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, builder => '_build_object_classes');
has 'key'               => (is => 'ro', isa => 'Str',           lazy => 1, builder => '_build_key');
has 'connection'        => (is => 'ro', isa => 'Nomura::EPS::NS::API::LDAP', required => 1);

# Create a new entry
#
sub create {
    my ($self, $params) = @_;

    # Create a Result object
    my $class = ref $self;
    $class =~ s/::ResultSet::/::Result::/;

    my $args = {
        result_set => $self,
    };
    for my $attr (keys %{$self->name_map}) {
        if (defined $params->{$attr}) {
            $args->{$attr} = $params->{$attr};
        }
        else {
            # Do some Moose Meta Magic to get the attribute type from the Result class
            my $attr_type = find_meta($class)->get_attribute($attr)->type_constraint->name;

            # If the moose attribute type is defined as an 'ArrayRef' then we want to
            # create the attribute with an empty list reference rather than leaving it undefined.
            if ($attr_type =~ m/^(Maybe\[)?ArrayRef/) {
                $args->{$attr} = [];
            }
        }
    }
    my $object = $class->new($args);

    if ($object->insert) {
        return $object;
    }
    return;
}

# Get a Result based on it's key
#
sub find {
    my ($self, $key) = @_;

    my $ldap_search = "(".$self->key."=$key)";
    my $mesg = $self->connection->ldap->search(base => $self->base, filter => $ldap_search);

    # We only expect one entry but it returns a list, so just take the first
    my ($entry) = $mesg->entries;

    if (! $entry) {
        return;
    }
    my $results = $self->_map_arguments([$entry]);

    if (@$results) {
        return $results->[0];
    }
    return;
}

# Search for a set of values
#
sub search {
    my ($self, $args) = @_;

    my $ldap_search = '';
TERM:
    for my $term (keys %{$self->name_map}) {
        next TERM if ! defined $args->{$term};

        $ldap_search .= "(".$self->name_map->{$term}."=".$args->{$term}.")";
    }
    $ldap_search = "(&${ldap_search})";
    my $mesg = $self->connection->ldap->search(base => $self->base, filter => $ldap_search);

    # Convert each entry into a Result object
    my @entries = $mesg->entries;

    my $results = $self->_map_arguments(\@entries);

    return $results;
}

# map the LDAP arguments onto the class attributes
#
sub _map_arguments {
    my ($self, $entries) = @_;

    # Create a Result object
    my $class   = ref $self;
    $class      =~ s/::ResultSet::/::Result::/;

    # Convert each entry into a Result object
    my @results;
    for my $entry (@$entries) {
        my $args = {
            result_set  => $self,
        };

        for my $attr (keys %{$self->name_map}) {
            # Do some Moose Meta Magic to get the attribute type from the Result class
            my $attr_type = find_meta($class)->get_attribute($attr)->type_constraint->name;

            # If the moose attribute type is defined as an 'ArrayRef' then we want to do
            # the LDAP get_value in list context, otherwise in scalar context
            #
            if ($attr_type =~ m/^(Maybe\[)?ArrayRef/) {
                $args->{$attr} = [$entry->get_value($self->name_map->{$attr})];
            }
            else {
                my $value = $entry->get_value($self->name_map->{$attr});
                if (defined $value && $value ne '') {
                    $args->{$attr} = $value;
                }

            }
        }

        my $result = $class->new($args);
        push @results, $result;
    }
    if (@results) {
        return \@results;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::ResultSet - Base class for an LDAP ResultSet

=head1 SYNOPSIS

    package Nomura::EPS::NS::API::LDAP::NCD::ResultSet::Group;

    use Moose;

    extends 'Nomura::EPS::NS::API::LDAP::ResultSet';

    sub _build_key { return 'cn'; }
    sub _build_base { return 'ou=groups,dc=nomura,dc=com'; }
    sub _build_object_classes { return [qw(top posixGroup ngbcompat groupofnames)]; };

    sub _build_name_map {
        return {
            group_name      => 'cn',
            gid_number      => 'gidNumber',
            member_uids     => 'memberUid',
            description     => 'description',
            user_password   => 'userPassword',
        };
    }

    no Moose;
    __PACKAGE__->meta->make_immutable;

    1;

=head1 DESCRIPTION

Creates a ResultSet class for an LDAP entry. See also X<lib/Nomura/EPS/NS/API/LDAP/Result.pm>

A ResultSet is the class used to fetch a set of results from LDAP.

=head1 ATTRIBUTES

Attributes are defined in the normal Moose manner, the following attributes are required and should
be created with suitable build methods as described below.

    sub _build_base { return 'ou=groups,dc=nomura,dc=com'; }

Attribute B<base> represents the base of the LDAP directory for the entry.

    sub _build_key { return 'cn'; }

Attribute B<key> is the final part of the distinguishing name

    sub _build_object_classes { return [qw(top posixGroup ngbcompat groupofnames)]; };

Attribute B<object_classes> determine schema rules the entry must follow.

The B<map_name> attribute determines the mapping from the standard API names (e.g. B<member_uids>) to the names used
in the LDAP directory (e.g. B<memberUid>)

=head1 METHODS

=head2 new

You would not normally call B<new> directly on a ResultSet, the normal method of creating one would be as follows

    $ncd = Nomura::EPS::NS::API::LDAP::NCD->new({
        host              => 'tl0067.lehman.com',
        base              => 'ou=consoles,dc=nomura,dc=com',
        dn                => 'cn=Directory Manager',
        password          => 'Secret',
        start_tls         => 0,
    });

    my $group_result_set  = $ncd->resultset('Group');

=head2 create

Create a new B<Result> object, insert it into the LDAP directory and return the object.

    $group = $group_result_set->create({
        group_name      => 'testing325',
        gid_number      => 1234465555,
        member_uids     => [qw(alpha beta gamma)],
        description     => ['description one'],
        user_password   => [qw(password1 password2 password3)],
    });

In the event that a record cannot be created an exception will be thrown.

=head2 find

Find a single entry based on its key

    $group = $group_result_set->find('testing325');

If the entry can be found, it is returned. Otherwise the method returns undef.


=head2 search

Search for entries that meet the search criteria.

    # Find all 'testing' entries and delete them
    my $groups = $group_result_set->search({
        group_name      => 'testing*',
        member_uids     => 'alpha',
    });
    for my $group (@$groups) {
        $group->delete;
    }

This example finds all groups where the B<group_name> begins with the string 'testing'
B<and> the member_uids contain an entry that exactly matches 'alpha'.

Note that if you search for multiple attributes the code carries out a logical B<and> on all these terms.
It is not possible at the moment to specify a logical B<or>.

Currently only a subset of the LDAP search criteria are supported. The B<wildcard> search using an asterix, e.g.
a search for '*smi*' will find any entry where substring 'smi' is anywhere in the string.

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut


