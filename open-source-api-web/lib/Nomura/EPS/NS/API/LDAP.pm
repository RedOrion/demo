package Nomura::EPS::NS::API::LDAP;

use Moose;
use Carp;
use Net::LDAP;
use Data::Dumper;

use Nomura::EPS::NS::API::Exception qw(throw_api_error);
use Nomura::EPS::NS::API::Constants qw(:API__ERROR);

has 'host'          => (is => 'ro', isa => 'Str', required => 1);
has 'base'          => (is => 'ro', isa => 'Str', required => 1);
has 'dn'            => (is => 'ro', isa => 'Str', required => 1);
has 'password'      => (is => 'ro', isa => 'Str', required => 1);
has 'start_tls'     => (is => 'ro', isa => 'Str', required => 1);
has 'ldap'          => (is => 'rw', isa => 'Net::LDAP', lazy => 1, builder => '_build_ldap');

# Lazy build of ldap connection
#
sub _build_ldap {
    my ($self) = @_;

    my $ldap = Net::LDAP->new($self->host);
    if (! $ldap) {
        throw_api_error
            errors  => [{
                message     => "Cannot create an LDAP connection",
                code        => $API__ERROR__NO_LDAP_CONNECTION,
                host        => ''.$self->host,
            }],
        ;
    }

    my $mesg = $ldap->bind($self->dn,password => $self->password);
    if ($mesg->code) {
        die "LDAP: Error code ".$mesg->code;
    }
    return $ldap;
}

# Create a ResultSet
#
sub resultset {
    my ($self, $class) = @_;

    my $c = ref $self;
    $c .= "::ResultSet::$class";

    my $rs = $c->new({
        connection  => $self,
    });

    return $rs;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=head1 NAME

Nomura::EPS::NS::API::LDAP - Base method for LDAP connections

=head1 DESCRIPTION

Base method for LDAP connections

=head1 SYNOPSIS

Subclass


=head1 METHODS

=head2 new

Create a new instance.

    my $connection = Nomura::EPS::NS::API::LDAP->new({
        host              => 'tl0067.lehman.com',
        base              => 'ou=consoles,dc=nomura,dc=com',
        dn                => 'cn=Directory Manager',
        password          => 'Secret',
        start_tls         => 0,
    });

=head2 resultset

Obtain a result set

    my $result_set = $connection('');

=head2 ACCESSORS

The following accessors are defined.

=over 4

=item * B<host> as given in the B<new> constructor - read only

=item * B<base> as given in the B<new> constructor - read only

=item * B<dn> as given in the B<new> constructor - read only

=item * B<password> as given in the B<new> constructor - read only

=item * B<start_tls> as given in the B<new> constructor - read only

=item * B<ldap> a X<NET::LDAP> object

=back

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
