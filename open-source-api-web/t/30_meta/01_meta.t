#!/usr/bin/env perl

# Tests for Meta module

use Moose;

use Test::More;
use FindBin::libs;
use Data::Dumper;
use DBICx::TestDatabase;
use Nomura::EPS::NS::API::Middleware::Factory;
use Nomura::EPS::NS::API::LDAP::NCD;
use Nomura::EPS::NS::API::LDAP::GCD;
use Nomura::EPS::NS::API::Middleware;

BEGIN {
    use_ok('Nomura::EPS::NS::Middleware::DB');
}

my $ncd = Nomura::EPS::NS::API::LDAP::NCD->new({
    host              => 'tl0067.lehman.com',
    base              => 'ou=consoles,dc=nomura,dc=com',
    dn                => 'cn=Directory Manager',
    password          => 'K0rolyov',
    start_tls         => 0,
});

isa_ok($ncd, 'Nomura::EPS::NS::API::LDAP::NCD');

my $gcd = Nomura::EPS::NS::API::LDAP::GCD->new({
    host        => 'us2132.uk.nomura.com',
    base        => 'l=EU,o=nomura.com',
    dn          => 'cn=Directory Manager',
    password    => '!babyl0ve',
    start_tls   => 0,
});

isa_ok($gcd, 'Nomura::EPS::NS::API::LDAP::GCD');

my $middleware = Nomura::EPS::NS::API::Middleware->new({
    ncd => $ncd,
    gcd => $gcd,
});

isa_ok($middleware, 'Nomura::EPS::NS::API::Middleware');

my $schema = DBICx::TestDatabase->new('Nomura::EPS::NS::Middleware::DB');
isa_ok($schema, 'DBIx::Class::Schema');

# Set up a simple configuration
my $version  = 1;
my $factory         = Nomura::EPS::NS::API::Middleware::Factory->new({
    schema          => $schema,
});
isa_ok($factory, 'Nomura::EPS::NS::API::Middleware::Factory');

my $configuration = $schema->resultset('Configuration')->create({
    name    => 'live_object_version',
    value   => $version,
});
isa_ok($configuration, 'Nomura::EPS::NS::Middleware::DB::Result::Configuration');

my $object_version = $schema->resultset('ObjectVersion')->create({
    id              => $version,
    description     => 'Test Version 1',
    fixed           => 1,
    on_date         => '2010:05:18 10:00:00',
    by_user         => 'docherti',
});
isa_ok($object_version, 'Nomura::EPS::NS::Middleware::DB::Result::ObjectVersion');

my $object = $schema->resultset('Object')->create({
    id                  => 1,
    name                => 'Console',
    object_version_id   => $version,
    resultset_class     => 'Nomura::EPS::NS::API::Middleware::ResultSet',
    result_class        => 'Nomura::EPS::NS::API::Middleware::Result',
});
isa_ok($object, 'Nomura::EPS::NS::Middleware::DB::Result::Object');

my $attr_hostname = $schema->resultset('Attribute')->create({
    object_id           => $object->id,
    name                => 'hostname',
    read_from_ldap      => 'ncd',
    is_ldap_key         => 1,
    tooltip             => 'Hostname tooltip text',
    readonly            => 1,
    required            => 1,
    isa_type            => 'Str',
    isa_array           => 0,
    isa_maybe           => 0,
});
isa_ok($attr_hostname, 'Nomura::EPS::NS::Middleware::DB::Result::Attribute');

my $attr_terminal_server = $schema->resultset('Attribute')->create({
    object_id           => $object->id,
    name                => 'terminal_server',
    read_from_ldap      => 'ncd',
    is_ldap_key         => 0,
    tooltip             => 'Terminal Server tooltip text',
    readonly            => 0,
    required            => 0,
    isa_type            => 'Str',
    isa_array           => 0,
    isa_maybe           => 1,
});
isa_ok($attr_terminal_server, 'Nomura::EPS::NS::Middleware::DB::Result::Attribute');

my $attr_terminal_port = $schema->resultset('Attribute')->create({
    object_id           => $object->id,
    name                => 'terminal_port',
    read_from_ldap      => 'ncd',
    is_ldap_key         => 0,
    tooltip             => 'Terminal Port tooltip text',
    readonly            => 0,
    required            => 0,
    isa_type            => 'Int',
    isa_array           => 0,
    isa_maybe           => 1,
});
isa_ok($attr_terminal_port, 'Nomura::EPS::NS::Middleware::DB::Result::Attribute');

my $write_hostname_attr_to_ncd = $schema->resultset('WriteAttributeTo')->create({
    attribute_id        => $attr_hostname->id,
    write_to_ldap       => 'ncd',
});
my $write_hostname_attr_to_gcd = $schema->resultset('WriteAttributeTo')->create({
    attribute_id        => $attr_hostname->id,
    write_to_ldap       => 'gcd',
});

my $write_terminal_server_attr_to_ncd = $schema->resultset('WriteAttributeTo')->create({
    attribute_id        => $attr_terminal_server->id,
    write_to_ldap       => 'ncd',
});
my $write_terminal_server_attr_to_gcd = $schema->resultset('WriteAttributeTo')->create({
    attribute_id        => $attr_terminal_server->id,
    write_to_ldap       => 'gcd',
});

my $write_terminal_port_attr_to_ncd = $schema->resultset('WriteAttributeTo')->create({
    attribute_id        => $attr_terminal_port->id,
    write_to_ldap       => 'ncd',
});
my $write_terminal_port_attr_to_gcd = $schema->resultset('WriteAttributeTo')->create({
    attribute_id        => $attr_terminal_port->id,
    write_to_ldap       => 'gcd',
});

# Now we have set up the database we can call the factory to create the Perl Objects
my $console_rs;
#my $console_rs = Nomura::EPS::NS::API::Middleware::ResultSet::Console->new({
#    middleware      => $middleware,
#});
#diag Dumper($console_rs);

$factory->update_meta_objects;

$console_rs = Nomura::EPS::NS::API::Middleware::ResultSet::Console->new({
    middleware      => $middleware,
});
isa_ok($console_rs, 'Nomura::EPS::NS::API::Middleware::ResultSet::Console');

diag Dumper($console_rs);

is_deeply($console_rs->attr, {
    key     => 'hostname',
    write_to    => {
        gcd     => [qw(terminal_server terminal_port)],
        ncd     => [qw(terminal_server terminal_port)],
    },
    read_from   => {
        gcd     => [],
        ncd     => [qw(hostname terminal_server terminal_port)],
    },
    tooltips    => {
        terminal_port   => 'Terminal Port tooltip text',
        hostname        => 'Hostname tooltip text',
        terminal_server => 'Terminal Server tooltip text',
    }
}, "Result Set Attribute hash");

my $console = Nomura::EPS::NS::API::Middleware::Result::Console->new({
    hostname        => 'test_123',
    resultset       => $console_rs,
});
isa_ok($console, 'Nomura::EPS::NS::API::Middleware::Result::Console');

done_testing();
