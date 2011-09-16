package Nomura::EPS::NS::API::LDAP::NCD::Result::Group;

use Moose;
use Carp;
use Data::Dumper;

extends 'Nomura::EPS::NS::API::LDAP::Result';

# Required attributes
has 'group_name'        => (is => 'ro', isa => 'Str');
has 'gid_number'        => (is => 'rw', isa => 'Int');

# Optional attributes
has 'description'       => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'member_uids'       => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');
has 'user_password'     => (is => 'rw', isa => 'Maybe[ArrayRef[Str]]');

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::NCD::Result::Group - NCD Result Group Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/Result.pm> to provide an interface to
the group data on the NCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<group_name> the name of the group on the LDAP server.

=item * B<gid_number> the GID number

=item * B<description> an optional array of description strings

=item * B<member_uids> an optional array of member UIDs

=item * B<user_password> an optional array of user passwords

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/Result.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
