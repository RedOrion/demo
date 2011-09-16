package Nomura::EPS::NS::API::Web;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use Log::Log4perl::Catalyst;

use Nomura::EPS::NS::API::LDAP::NCD;
use Nomura::EPS::NS::API::LDAP::GCD;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in nomura_eps_ns_api_web.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'Nomura::EPS::NS::API::Web',
    default_view	=> 'TT',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

my $ncd = Nomura::EPS::NS::API::LDAP::NCD->new({
    host        => 'tl0067.lehman.com',
    base        => 'dc=nomura,dc=com',
    dn          => 'cn=Directory Manager',
    password    => 'K0rolyov',
    start_tls   => 0,
});
my $gcd = Nomura::EPS::NS::API::LDAP::GCD->new({
    host        => 'us2132.uk.nomura.com',
    base        => 'l=EU,o=nomura.com',
    dn          => 'cn=Directory Manager',
    password    => '!babyl0ve',
    start_tls   => 0,
});

__PACKAGE__->config(
    'Model::Middleware' => {
        class   => 'Nomura::EPS::NS::API::Middleware',
        args    => {
            ncd => $ncd,
            gcd => $gcd,
        }
    }
);

my $log4perl_conf_file = 'nomura_eps_ns_api_web.log4perl.conf';
__PACKAGE__->log(Log::Log4perl::Catalyst->new($log4perl_conf_file));

Log::Log4perl->init($log4perl_conf_file);

# Start the application
__PACKAGE__->setup();

no Moose;
__PACKAGE__->meta->make_immutable;
1;


=head1 NAME

Nomura::EPS::NS::API::Web - Catalyst based application

=head1 SYNOPSIS

    script/nomura_eps_ns_api_web_server.pl

=head1 DESCRIPTION

RESTful API into the LDAP services

=head1 SEE ALSO

L<Nomura::EPS::NS::API::Web::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
