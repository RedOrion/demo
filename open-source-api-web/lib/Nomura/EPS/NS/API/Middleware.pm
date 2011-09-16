package Nomura::EPS::NS::API::Middleware;

use Moose;
use Carp;
use Module::Find;
use File::Spec;
use File::Find;

# On adding new LDAP servers add them here and also in the class method 'ldap_server_names' below
has 'ncd'               => (is => 'rw', isa => 'Nomura::EPS::NS::API::LDAP::NCD', required => 1);
has 'gcd'               => (is => 'rw', isa => 'Nomura::EPS::NS::API::LDAP::GCD', required => 1);

BEGIN {
    # Load all plugins
    useall Nomura::EPS::NS::API::LDAP;
    useall Nomura::EPS::NS::API::Middleware;
}

# Return LDAP server names (Class method)
#
sub ldap_server_names {
    my ($class) = @_;

    return [qw(ncd gcd)];
}

# Create a ResultSet
#
sub resultset {
    my ($self, $class) = @_;

    my $c = ref $self;
    $c .= "::ResultSet::$class";

    my $rs = $c->new({
        middleware  => $self,
    });

    return $rs;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Nomura::EPS::NS::API::Middleware - Base method for Middleware classes

=head1 DESCRIPTION

Base method for Middleware classes.

The Middleware is Content-Centric Middleware which provides a simple abstraction
through which applications can issue requests for content, without worrying about
which LDAP server the content is obtained from.

=head1 SYNOPSIS

    my $middleware = Nomura::EPS::NS::API::Middleware->new({
        ncd     => $ncd,
        gcd     => $gcd,
    });

    my $console_rs = $middleware->resultset('Console');

=head1 METHODS

=head2 new

Create a new instance.

    my $middleware = Nomura::EPS::NS::API::Middleware->new({
        ncd     => $ncd,
        gcd     => $gcd,
    });

B<ncd> and B<gcd> are X<lib/Nomura/EPS/NS/API/LDAP/NCD.pm> and
X<lib/Nomura/EPS/NS/API/LDAP/GCD.pm> objects respectively.

=head2 resultset

Obtain a result set

    my $console_rs = $middleware->resultset('Console');

=head2 ldap_server_names

Return a list of the LDAP server names known by the application

    my @ldap_names = @{$middleware->ldap_server_names};

=head2 ACCESSORS

The following accessors are defined.

=over 4

=item * B<ncd> as given in the B<new> constructor - read only

=item * B<gcd> as given in the B<new> constructor - read only

=back

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2011 Nomura Holdings, Inc. All rights reserved.

=cut
