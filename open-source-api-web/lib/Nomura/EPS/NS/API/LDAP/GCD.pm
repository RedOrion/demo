package Nomura::EPS::NS::API::LDAP::GCD;

use Moose;
use Carp;

extends 'Nomura::EPS::NS::API::LDAP';

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Nomura::EPS::NS::API::LDAP::GCD - GCD Base Class

=head1 DESCRIPTION

Only a constructor method is provided by this class, everything else
is provided by X<lib/Nomura/EPS/NS/API/LDAP.pm> which this class extends.

=head1 SYNOPSIS

    $gcd = Nomura::EPS::NS::API::LDAP::GCD->new({
        host              => 'us2132.uk.nomura.com',
        base              => 'l=EU,o=nomura.com',
        dn                => 'cn=Directory Manager',
        password          => 'secret',
        start_tls         => 0,
    });

    # resultset method provided by the base class
    my $console_rs = $gcd->resultset('Console');

=head1 METHODS

=head2 new

Create a new instance.

    $gcd = Nomura::EPS::NS::API::LDAP::GCD->new({
        host              => 'us2132.uk.nomura.com',
        base              => 'l=EU,o=nomura.com',
        dn                => 'cn=Directory Manager',
        password          => 'secret',
        start_tls         => 0,
    });

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
