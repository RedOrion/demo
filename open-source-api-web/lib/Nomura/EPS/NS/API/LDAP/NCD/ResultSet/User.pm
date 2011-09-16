package Nomura::EPS::NS::API::LDAP::NCD::ResultSet::User;

use Moose;
use Carp;

extends 'Nomura::EPS::NS::API::LDAP::ResultSet';

sub _build_key { return 'uid'; }

sub _build_base { return 'ou=employees,ou=people,ou=users,dc=nomura,dc=com'; }

sub _build_object_classes {
    return [qw(
        top shadowaccount posixAccount person organizationalPerson inetorgperson ngbcompat
        krbprincipalaux krbTicketPolicyAux)];
}

sub _build_name_map {
    return {
        login_shell     => 'loginShell',
        employee_number => 'employeeNumber',
        given_name      => 'givenName',
        surname         => 'sn',
        full_name       => 'cn',
        gid_number      => 'gidNumber',
        home_directory  => 'homeDirectory',
        uid             => 'uid',
        uid_number      => 'uidNumber',
        description     => 'description',
        user_password   => 'userPassword',
        last_password_change    => 'krbLastPwdChange',
        password_expiry_date    => 'krbPasswordExpiration',
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::NCD::ResultSet::User - NCD ResultSet User Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm> to provide an interface to
the user data on the NCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<full_name> maps to the B<cn> attribute on the NCD server

=item * B<login_shell> maps to the B<cn> attribute on the NCD server

=item * B<employee_number> maps to the B<cn> attribute on the NCD server

=item * B<given_name> maps to the B<cn> attribute on the NCD server

=item * B<surname> maps to the B<cn> attribute on the NCD server

=item * B<gid_number> maps to the B<gidNumber> attribute on the NCD server

=item * B<home_directory> maps to the B<homeDirectory> attribute on the NCD server

=item * B<uid> maps to the B<uid> attribute on the NCD server

=item * B<uid_descriptio> maps to the B<uidNumber> attribute on the NCD server

=item * B<description> maps to the B<description> attribute on the NCD server

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
