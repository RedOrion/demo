package Nomura::EPS::NS::API::LDAP::GCD::Result::Group;

use Moose;
use Carp;
use Data::Dumper;

extends 'Nomura::EPS::NS::API::LDAP::Result';

# Required attributes
has 'group_name'        => (is => 'ro', isa => 'Str');
has 'gid_number'        => (is => 'rw', isa => 'Int');

# Optional attributes
has 'member_uids'       => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'domains'           => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'group_locations'   => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'group_options'     => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'group_owners'      => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'last_changes'      => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'menus'             => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'passwords'         => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'support_departments'   => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::GCD::Result::Group - GCD Result Group Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/Result.pm> to provide an interface to
the group data on the GCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<group_name> the name of the group on the LDAP server.

=item * B<gid_number> the GID number

=item * B<member_uids> an optional array of member UIDs

=item * B<domains> an optional array of domain names

=item * B<group_locations> an optional array of group locations

=item * B<group_options> an optional array of group options

=item * B<group_owners> an optional array of group owners

=item * B<last_changes> an optional array of last changed times and dates

=item * B<menus> an optional array of menus

=item * B<passwords> an optional array of passwords

=item * B<support_departments> an optional array of support departments

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/Result.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
