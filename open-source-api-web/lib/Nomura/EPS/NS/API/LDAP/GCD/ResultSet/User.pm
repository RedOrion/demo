package Nomura::EPS::NS::API::LDAP::GCD::ResultSet::User;

use Moose;
use Carp;

extends 'Nomura::EPS::NS::API::LDAP::ResultSet';

sub _build_key { return 'uid'; }

sub _build_base { return 'ou=people,l=EU,o=nomura.com'; }

sub _build_object_classes {
    return [qw(
        top shadowaccount posixAccount person organizationalPerson ngbservice ngbportalperson ngbperson
        nbgpeoplesoft mailrecipient inetorgperson
    )];
}

# shadowaccount
#   MUST
#       uid,userid              - DirectoryString   - multi
#   MAY
#       description             - DirectoryString   - multi
#       shadowExpire            - Integer           - single
#       shadowFlag              - Integer           - single
#       shadowInactive          - Integer           - single
#       shadowLastChange        - Integer           - single
#       shadowMax               - Integer           - single
#       shadowMin               - Integer           - single
#       shadowWarning           - Integer           - single
#       userPassword            - OctetString       - multi
#
# posixAccount
#   MUST
#       cn, commonName          - DirectoryString   - multi
#       gidNumber               - Integer           - single
#       homeDirectory           - IA5String         - single
#       uid, userid             - DirectoryString   - multi
#       uidNumber               - Integer           - single
#   MAY
#       description             - DirectoryString   - multi
#       gecos                   - DirectoryString   - single
#       loginShell              - IA5String         - single
#       userPassword            - OctetString       - multi
#
# person
#   MUST
#       cn, commonName          - DirectoryString   - multi
#       sn, surName             - DirectoryString   - multi
#       description             - DirectoryString   - multi
#       seeAlso                 - DN                - multi
#       telephoneNumber         - TelephoneNumber   - multi
#       userPassword            - OctetString       - multi
#
# organizationalPerson
#   MUST
#       cn, commonName          - DirectoryString   - multi
#   MAY
#       loads, starting with 'mds...'
#
# ngbservice
#   MUST
#       -
#   MAY
#       memberOf                - DN                - multi
#       loads, starting with 'ngb...' e.g. 'ngbblackberry'
#
# ngbportalperson
#   MUST
#       -
#   MAY
#       loads...
#
#
# ngbperson
#   MUST
#       -
#   MAY
#       loads...
#
#
# ngbpeoplesoft
#   MUST
#       cn, commonName          - DirectoryString   - multi
#       employeeNumber          - DirectoryString   - single
#       uid,userid              - DirectoryString   - multi
#   MAY
#       loads...
#
# mailRecipient
#   MUST
#       -
#   MAY
#       loads... mostly starting 'mail...'
#
# inetorgperson
#   MUST
#       cn, commonName          - DirectoryString   - multi
#       sn, surName             - DirectoryString   - multi
#   MAY
#       employeeNumber
#       givenName
#       initials
#       title
#       sn
#       userPassword
#       loads more...
#

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
        gender          => 'sex',
        salutation      => 'title',
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::GCD::ResultSet::User - GCD ResultSet User Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm> to provide an interface to
the user data on the GCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<full_name> maps to the B<cn> attribute on the GCD server

=item * B<login_shell> maps to the B<cn> attribute on the GCD server

=item * B<employee_number> maps to the B<cn> attribute on the GCD server

=item * B<given_name> maps to the B<cn> attribute on the GCD server

=item * B<surname> maps to the B<cn> attribute on the GCD server

=item * B<gid_number> maps to the B<gidNumber> attribute on the GCD server

=item * B<home_directory> maps to the B<homeDirectory> attribute on the GCD server

=item * B<uid> maps to the B<uid> attribute on the GCD server

=item * B<uid_number> maps to the B<uidNumber> attribute on the GCD server

=item * B<gender> maps to the B<sex> attribute on the GCD server

=item * B<salutation> maps to the B<title> attribute on the GCD server

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
