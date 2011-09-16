#!/usr/bin/env perl

use strict;
use warnings;
use FindBin::libs;
use Test::More;
use HTTP::Request::Common;
use Data::Dumper;
use JSON;
use Catalyst::Test 'Nomura::EPS::NS::API::Web';
use Nomura::EPS::NS::API::Middleware;

$Data::Dumper::Indent = 1;

my $ncd = Nomura::EPS::NS::API::LDAP::NCD->new({
    host              => 'tl0067.lehman.com',
    base              => 'ou=groups,dc=nomura,dc=com',
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

my $ncd_group_rs    = $ncd->resultset('Group');
my $ncd_groups      = $ncd_group_rs->search({group_name => 'testing*'});
for my $group (@$ncd_groups) {
    # Read the full record
    $group = $ncd_group_rs->find($group->group_name);
    $group->delete;
}

my $gcd_group_rs    = $gcd->resultset('Group');
my $gcd_groups      = $gcd_group_rs->search({group_name => 'testing*'});
for my $group (@$gcd_groups) {
    # Read the full record
    $group = $gcd_group_rs->find($group->group_name);
    $group->delete;
}

# Test that there are no records remaining
my ($ncd_rs, $gcd_rs, $ncd_group, $gcd_group);

$ncd_rs      = $ncd->resultset('Group');
$gcd_rs      = $gcd->resultset('Group');

($ncd_group)  = $ncd_rs->search({group_name => 'testing*'});
($gcd_group)  = $gcd_rs->search({group_name => 'testing*'});

is($ncd_group, undef, "All NCD groups have been deleted");
is($gcd_group, undef, "All GCD groups have been deleted");

#################################
# Create a new entry through the API
#################################
my ($content, $response);

$content = encode_json {
    gid_number      => 666666,
    description     => ['description 666666'],
    user_password   => ['secret'],
};

$response = request(PUT '/api/group/testing_995',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Test various aspects about the response.
is($response->code, 200, 'Response code for PUT');
is($response->message, 'OK', 'Response message is OK');
is($response->header('content-type'), 'application/json', 'Response content type');

# Test the record in the GCD and NCD databases
$ncd_group = $ncd_rs->find('testing_995');
isnt($ncd_group, undef, "NCD Returns a record");

is($ncd_group->group_name, 'testing_995', 'NCD group_name');

$gcd_group = $gcd_rs->find('testing_995');
isnt($gcd_group, undef, "GCD Returns a record");

is($gcd_group->group_name, 'testing_995', 'GCD group_name');

#################################
# Read a single entry through the API
#################################

$response = request(GET '/api/group/testing_995',
    Content_Type    => 'application/json',
);

my $res_hash = decode_json $response->content;

is($res_hash->{data}{group_name}, 'testing_995', "GET group_name");
is($res_hash->{data}{gid_number}, 666666, "GET gid_number");
is_deeply($res_hash->{data}{description}, ['description 666666'], "GET description");
is_deeply($res_hash->{data}{member_uids}, [], "GET member_uids");

### Test that multi-value fields are inserted correctly in the database

$content = encode_json {
    gid_number      => 666667,
    description     => ['description 996 one','description 996 two'],
    user_password   => ['secret'],
};

$response = request(PUT '/api/group/testing_996',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Test various aspects about the response.
is($response->code, 200, 'Response code for PUT');
is($response->message, 'OK', 'Response message is OK');
is($response->header('content-type'), 'application/json', 'Response content type');

# Read the record back through the API

$response = request(GET '/api/group/testing_996',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;

is_deeply($res_hash->{data}{description}, ['description 996 one','description 996 two'], "GET multi description");

#################################
# Search methods
#################################

# Add a few more records to search on
$content = encode_json {
    gid_number      => 666668,
    description     => ['description 997 one','description 997 two'],
    user_password   => ['secret'],
};

$response = request(PUT '/api/group/testing_997',
    Content_Type    => 'application/json',
    Content         => \$content,
);

$content = encode_json {
    gid_number      => 666001,
    description     => ['description 001 one','description 001 two'],
    user_password   => ['secret'],
};

$response = request(PUT '/api/group/testing_001',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Search for something that does not exist
$response = request(GET '/api/group/?gid_number=666000',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;
is($response->code, 200, 'Response code for Search returning nothing');
is_deeply($res_hash, [], 'Empty array for Search returning nothing');

# Search for all the '6666*' gid_numbers
$response = request(GET '/api/group/?gid_number=6666*',
    Content_Type    => 'application/json',
);

$res_hash = decode_json $response->content;

is(scalar @$res_hash, 3, "There are three entries");
my @results = sort { $a->{data}{gid_number} cmp $b->{data}{gid_number} } @$res_hash;

is($results[0]->{data}{gid_number}, 666666, "Search gid_number 0");
is($results[1]->{data}{gid_number}, 666667, "Search gid_number 1");
is($results[2]->{data}{gid_number}, 666668, "Search gid_number 2");

done_testing;
exit;


