package Nomura::EPS::NS::API::LDAP::NCD::ResultSet::Console;

use Moose;
use Carp;

extends 'Nomura::EPS::NS::API::LDAP::ResultSet';

sub _build_key { return 'cn'; }

sub _build_base { return 'ou=consoles,dc=nomura,dc=com'; }

sub _build_object_classes { return [qw(ngbconsoles top)]; };

sub _build_name_map {
    return {
        hostname        => 'cn',
        terminal_server => 'ngbConsolesTeminalServer',
        terminal_port   => 'ngbConsolesTerminalPort',
        admin_port      => 'ngbConsolesAdminPort',
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::NCD::ResultSet::Console - NCD ResultSet Console Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm> to provide an interface to
the console data on the NCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<hostname> maps to the B<cn> attribute on the NCD server

=item * B<terminal_server> maps to the B<ngbConsolesTeminalServer> on the NCD server

=item * B<terminal_port> maps to the B<> on the NCD server

=item * B<admin_port> maps to the admin port on the server.

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/ResultSet.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
