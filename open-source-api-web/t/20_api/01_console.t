#!/usr/bin/env perl

use strict;
use warnings;
use FindBin::libs;
use Test::More;
use HTTP::Request::Common qw(GET PUT DELETE POST);
use Data::Dumper;
use JSON;
use Catalyst::Test 'Nomura::EPS::NS::API::Web';
use Nomura::EPS::NS::API::Middleware;
use Nomura::EPS::NS::API::Constants qw(:API__ERROR);
use Nomura::EPS::NS::Middleware::DB;

$Data::Dumper::Indent = 1;

#### Set up objects ####
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

my $middleware = Nomura::EPS::NS::API::Middleware->new({
    ncd => $ncd,
    gcd => $gcd,
});

isa_ok($middleware, 'Nomura::EPS::NS::API::Middleware');

# Delete all test Console objects
my $console_rs = $middleware->resultset('Console');

my $consoles = $console_rs->search({hostname => 'test*'});

for my $console (@$consoles) {
    # Read the full record
    $console = $console_rs->find($console->hostname);
    diag "Deleting record ".$console->hostname."\n";
    $console->delete;
}

# Test that there are no records remaining
my ($ncd_rs, $gcd_rs, $ncd_console, $gcd_console);

$ncd_rs      = $ncd->resultset('Console');
$gcd_rs      = $gcd->resultset('Console');

($ncd_console)  = $ncd_rs->search({hostname => 'test*'});
($gcd_console)  = $gcd_rs->search({hostname => 'test*'});

is($ncd_console, undef, "All NCD consoles have been deleted");
is($gcd_console, undef, "All GCD consoles have been deleted");

#################################
# Create a new entry through the API
#################################
my ($content, $response);

$content = encode_json {
    terminal_server => 'ts_test_997',
    terminal_port   => 997,
    admin_port      => 97,
};

$response = request(PUT '/rest/console/testing_997',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Test various aspects about the response.
is($response->code, 200, 'Response code for PUT');
is($response->header('content-type'), 'application/json', 'Response content type');

my $res_hash = decode_json $response->content;
is_deeply($res_hash->{data}, {
    terminal_port   => 997,
    terminal_server => 'ts_test_997',
    admin_port      => 97,
    hostname        => 'testing_997',
    },
    'PUT response data',
);

# Delete the entry through the interface
$response = request(DELETE '/rest/console/testing_997',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;

is_deeply($res_hash->{data}{data}, {
    terminal_port   => '997',
    terminal_server => 'ts_test_997',
    admin_port      => '97',
    hostname        => 'testing_997',
});

# Try to delete an already deleted item
$response = request(DELETE '/rest/console/testing_997',
    Content_Type    => 'application/json',
);
$res_hash = decode_json $response->content;
is_deeply($res_hash, {
    errors  => [{ message => 'Could not find that record.', code => $API__ERROR__CANNOT_FIND_RECORD }]
}, "DELETE a none existant record");


# RE-create the entry through the API
$content = encode_json {
    terminal_server => 'ts_test_997',
    terminal_port   => 997,
    admin_port      => 97,
};

$response = request(PUT '/rest/console/testing_997',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Test various aspects about the response.
is($response->code, 200, 'Response code for PUT');
is($response->header('content-type'), 'application/json', 'Response content type');

$res_hash = decode_json $response->content;
is_deeply($res_hash->{data}, {
    terminal_port   => 997,
    terminal_server => 'ts_test_997',
    admin_port      => 97,
    hostname        => 'testing_997',
    },
    'PUT response data',
);

# Search for the record on an illegal field

$response = request(GET '/rest/console?admin_port=97',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Test various aspects about the response.
is($response->code, 200, 'Response code for GET with search');

$res_hash = decode_json $response->content;
diag Dumper($res_hash);

is_deeply($res_hash,
    {
        errors  => [{
            message     => 'Cannot search on that field',
            code        => $API__ERROR__ILLEGAL_SEARCH_TERM,
            attribute   => 'admin_port',
        }]
    },
    'Search on an illegal term',
);

# Test the record in the GCD and NCD databases
$ncd_console = $ncd_rs->find('testing_997');

is($ncd_console->hostname, 'testing_997', 'NCD hostname');
is($ncd_console->terminal_server, 'ts_test_997', 'NCD terminal server');
is($ncd_console->terminal_port, 997, 'NCD terminal port');

$gcd_console = $gcd_rs->find('testing_997');

is($gcd_console->hostname, 'testing_997', 'GCD hostname');
is($gcd_console->terminal_server, 'ts_test_997', 'GCD terminal server');
is($gcd_console->terminal_port, 997, 'GCD terminal port');
is($gcd_console->admin_port, 97, 'GCD Admin Port');

#################################
# Read a single entry through the API
#################################

$response = request(GET '/rest/console/testing_997',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;

is($res_hash->{data}{terminal_port}, 997, "Response terminal port");
is($res_hash->{data}{admin_port}, 97, "Response admin port");
is($res_hash->{data}{hostname}, 'testing_997', "Response hostname");
is($res_hash->{data}{terminal_server}, 'ts_test_997', "Response terminal server");

#################################
# Search methods
#################################

# Add a few more records to search on
$content = encode_json {
    terminal_server => 'ts_test_1000',
    terminal_port   => 1000,
    admin_port      => 95,
};
$response = request(PUT '/rest/console/testing_1000',
    Content_Type    => 'application/json',
    Content         => \$content,
);

$content = encode_json {
    terminal_server => 'ts_test_1001',
    terminal_port   => 1001,
    admin_port      => 95,
};
$response = request(PUT '/rest/console/testing_1001',
    Content_Type    => 'application/json',
    Content         => \$content,
);

$content = encode_json {
    terminal_server => 'ts_test_2000',
    terminal_port   => 2000,
    admin_port      => 45,
};
$response = request(PUT '/rest/console/testing_2000',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Search for something that does not exist
$response = request(GET '/rest/console/?hostname=testing_300*',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;
is($response->code, 200, 'Response code for Search returning nothing');
is_deeply($res_hash->{data}, [], 'Empty array for Search returning nothing');


# Search for all the '100x' records
$response = request(GET '/rest/console/?hostname=testing_100*',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;

is(scalar @{$res_hash->{data}}, 2, "There are two entries");
my @results = sort { $a->{data}{terminal_port} cmp $b->{data}{terminal_port} } @{$res_hash->{data}};

for my $i (0..1) {
    my $entry = $res_hash->{data}[$i]{data};
    is($entry->{terminal_port},     $i+1000,            "Search terminal port $i");
    is($entry->{nonce},             undef,              "Search nonce $i");
    is($entry->{admin_port},        undef,              "Search Admin Port $i");
    is($entry->{hostname},          "testing_100$i",    "Search Hostname $i");
    is($entry->{terminal_server},   "ts_test_100$i",    "Search Terminal Server $i");
}

# Compound search, including terminal port
$response = request(GET '/rest/console/?hostname=testing_100*&terminal_port=1001',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;
is(scalar @{$res_hash->{data}}, 1, "Compound with Terminal Port search, one entry");
is($res_hash->{data}[0]{nonce}, undef, "Compound with Terminal Port search, no nonce");
is($res_hash->{data}[0]{data}{hostname}, 'testing_1001', "Compound with Terminal Port search, hostname");

# Compound search, including terminal server
$response = request(GET '/rest/console/?hostname=testing_1001&terminal_server=ts_test_100*',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;
is(scalar @{$res_hash->{data}}, 1, "Compound with Terminal Server search, one entry");
is($res_hash->{data}[0]{nonce}, undef, "Compound with Terminal Server search, no nonce");
is($res_hash->{data}[0]{data}{admin_port}, undef, "Compound with Terminal Server search, no Admin Port");
is($res_hash->{data}[0]{data}{hostname}, 'testing_1001', "Compound with Terminal Server search, hostname");

# Compound search, including admin port
$response = request(GET '/rest/console/?hostname=testing_100*&admin_port=95',
    Content_Type    => 'application/json',
);

done_testing;
exit;


