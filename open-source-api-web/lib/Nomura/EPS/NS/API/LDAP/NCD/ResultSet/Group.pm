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

=head1 NAME

Nomura::EPS::NS::API::LDAP::NCD::ResultSet::Group - NCD ResultSet Group Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm> to provide an interface to
the group data on the NCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<group_name> maps to the B<cn> attribute on the NCD server

=item * B<gid_number> maps to the B<gidNumber> on the NCD server

=item * B<member_uids> maps to the B<MemberUid> on the NCD server

=item * B<descriptyon> maps to the B<description> on the server.

=item * B<user_password> maps to the B<description> entry on the server.

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
