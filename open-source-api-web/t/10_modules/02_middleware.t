#!/usr/bin/env perl

# Basic tests of the LDAP interface

use strict;
use warnings;
use Test::More;
use Test::MockModule;
use FindBin::libs;
use Data::Dumper;
use Module::Find;
use Nomura::EPS::NS::API::Middleware;
use Nomura::EPS::NS::Middleware::DB;

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

my $schema = Nomura::EPS::NS::Middleware::DB->connect(
    'DBI:mysql:host=localhost;database=icydee_app',
    'icydee_app',
    'icydee_app',
    { AutoCommit => 1}
);

my $factory         = Nomura::EPS::NS::API::Middleware::Factory->new({
    schema          => $schema,
});
isa_ok($factory, 'Nomura::EPS::NS::API::Middleware::Factory');

# Update the Middleware from the database
$factory->update_meta_objects;

my $console_rs = $middleware->resultset('Console');

isa_ok($console_rs, 'Nomura::EPS::NS::API::Middleware::ResultSet::Console');

# remove any existing test records
my $consoles = $console_rs->search({hostname => 'testing*'});
for my $console (@$consoles) {
    # Read the full record
    $console = $console_rs->find($console->hostname);
    $console->delete;
}

# Create some test data
my $console = $console_rs->create({
    hostname        => 'testing_123',
    terminal_server => 'test_ts_123',
    terminal_port   => 1123,
    admin_port      => 23,
});

# Check that we can find the test data we just created
my $new_console = $console_rs->find('testing_123');

isa_ok($new_console, 'Nomura::EPS::NS::API::Middleware::Result::Console');

is($new_console->hostname,          'testing_123',  "created hostname is correct");
is($new_console->terminal_server,   'test_ts_123',  "created terminal_server is correct");
is($new_console->terminal_port,     '1123',         "created terminal_port is correct");
is($new_console->admin_port,        '23',           "created admin_port is correct");

# Create some more test data
$console = $console_rs->create({
    hostname        => 'testing_124',
    terminal_server => 'test_ts_124',
    terminal_port   => 1124,
    admin_port      => 24,
});

# Test the search
$consoles = $console_rs->search({hostname => 'testing*'});
is(scalar @$consoles, 2, "Number of test consoles");

for my $console (@$consoles) {
    # Ensure we can't write back a record we read as a result of a search

    eval {
        $console->update;
    };
    my $e = $@;
    if ($e) {
        isa_ok($e, 'Nomura::EPS::NS::API::Exception');
    }
}


done_testing();
