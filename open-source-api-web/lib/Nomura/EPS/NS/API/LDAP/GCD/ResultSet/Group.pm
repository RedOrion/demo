package Nomura::EPS::NS::API::LDAP::GCD::ResultSet::Group;

use Moose;

extends 'Nomura::EPS::NS::API::LDAP::ResultSet';

sub _build_key { return 'cescn'; }
sub _build_base { return 'ou=groups,ou=NIS,ou=services,l=EU,o=nomura.com'; }
sub _build_object_classes { return [qw(top ngbnisgroup)]; };

sub _build_name_map {
    return {
        group_name          => 'cescn',
        gid_number          => 'gidNumber',
        member_uids         => 'memberUid',
        domains             => 'ngbdomains',
        group_locations     => 'ngbgrouplocation',
        group_options       => 'ngbgroupoptions',
        group_owners        => 'ngbgroupowners',
        last_changes        => 'ngblastchanged',
        menus               => 'ngbmenus',
        passwords           => 'ngbpassword',
        support_departments => 'ngbsupportdept',
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::GCD::ResultSet::Group - GCD ResultSet Group Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm> to provide an interface to
the group data on the GCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<group_name> maps to the B<cn> attribute on the GCD server

=item * B<gid_number> maps to the B<gidNumber> on the GCD server

=item * B<member_uids> maps to the B<MemberUid> on the GCD server

=item * B<domains> maps to the B<ngbdomains> entry on the server.

=item * B<group_locations> maps to the B<ngbgrouplocation> entry on the server.

=item * B<group_options> maps to the B<ngbgroupoptions> entry on the server.

=item * B<group_owners> maps to the B<ngbgroupowners> entry on the server.

=item * B<last_changes> maps to the B<ngblastchanged> entry on the server.

=item * B<menus> maps to the B<ngbmenus> entry on the server.

=item * B<passwords> maps to the B<ngbpassword> entry on the server.

=item * B<support_departments> maps to the B<ngbsupportdept> entry on the server.

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
