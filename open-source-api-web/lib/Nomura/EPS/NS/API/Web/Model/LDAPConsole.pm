package Nomura::EPS::NS::API::Web::Model::LDAPConsole;

use strict;
use warnings;
use base qw/Catalyst::Model::LDAP/;

__PACKAGE__->config(
    host              => 'tl0067.lehman.com',
    base              => 'ou=consoles,dc=nomura,dc=com',
    dn                => 'cn=Directory Manager',
    password          => 'K0rolyov',
    start_tls         => 0,
);

=head1 NAME

Nomura::EPS::NS::API::Web::Model::LDAPConsole - Model into the LDAP Console

=head1 DESCRIPTION

A thin wrapper around L<Catalyst::Model::LDAP> interfacing to the LDAP Console data

=head1 METHODS

None.

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut

1;
