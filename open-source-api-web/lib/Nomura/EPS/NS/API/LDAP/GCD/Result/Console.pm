package Nomura::EPS::NS::API::LDAP::GCD::Result::Console;

use Moose;
use Carp;

extends 'Nomura::EPS::NS::API::LDAP::Result';

has 'hostname'          => (is => 'ro', isa => 'Str', required => 1);
has 'terminal_server'   => (is => 'rw', isa => 'Maybe[Str]');
has 'terminal_port'     => (is => 'rw', isa => 'Maybe[Int]');
has 'admin_port'        => (is => 'rw', isa => 'Maybe[Int]');

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::GCD::Result::Console - GCD Result Console Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/Result.pm> to provide an interface to
the console data on the GCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<hostname> the host name of the LDAP server.

=item * B<terminal_server> the name of the terminal server.

=item * B<terminal_port> the terminal server port number

=item * B<admin_port> the administration port number.

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/Result.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
