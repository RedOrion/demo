#!/usr/bin/env perl

use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Data::Serializer;
use XML::Simple;
use HTTP::Request::Common qw(GET DELETE PUT POST);
use Data::Dumper;
use JSON;
use Catalyst::Test 'Nomura::EPS::NS::API::Web';
use Nomura::EPS::NS::API::Middleware;
use Nomura::EPS::NS::API::Constants qw(:API__ERROR);

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

# Delete the test data through the Middleware layer
my $ncd_user_rs     = $ncd->resultset('User');
my $ncd_users       = $ncd_user_rs->search({uid => 'test*'});
for my $user (@$ncd_users) {
    $user = $ncd_user_rs->find($user->uid);
    $user->delete;
}
my $gcd_user_rs     = $gcd->resultset('User');
my $gcd_users       = $gcd_user_rs->search({uid => 'test*'});
for my $user (@$gcd_users) {
    $user = $gcd_user_rs->find($user->uid);
    $user->delete;
}

my ($ncd_user)  = $ncd_user_rs->search({uid => 'test*'});
my ($gcd_user)  = $gcd_user_rs->search({uid => 'test*'});

is($ncd_user, undef, "All NCD test users have been deleted");
is($gcd_user, undef, "All GCD test users have been deleted");

my (@errors, $content, $response, $response_hash, $sub_error);

#################################
# Try to delete an entry that does not exist
#################################

$response = request(DELETE '/rest/user/test001',
    Content_Type    => 'application/json',
);

# There should be one error indicating a missing record
is($response->code, 200, 'Response code for DELETE');
$response_hash = decode_json $response->content;
isnt($response_hash->{errors}, undef, "There are errors for DELETE");
if ($response_hash->{errors}) {
    @errors = @{$response_hash->{errors}};
    is(scalar @errors, 1, "There is only one error for DELETE");
    my $error = $errors[0];
    is($error->{code}, $API__ERROR__CANNOT_FIND_RECORD, "Error code for DELETE");
}

#################################
# Create a new entry through the API
#################################

my $hash_ref = {
    uid             => 'test001',
    uid_number      => 11112222,
    gid_number      => 20,
    surname         => 'Smith',
    full_name       => 'John Smith',
    employee_number => 'EU11112222',
    home_directory  => '/home/smith001',
    login_shell     => '/bin/csh',
};

#exit;

my $content = encode_json $hash_ref;

$response = request(PUT '/rest/user/test001',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# Test various aspects about the response.
is($response->code, 200, 'Response code for PUT');
is($response->message, 'OK', 'Response message is OK');
is($response->header('content-type'), 'application/json', 'Response content type');

# Test the record in the NCD database
$ncd_user = $ncd_user_rs->find('test001');
isnt($ncd_user, undef, "NCD Returns a record");

### An update without the nonce should return an error
##$response = request(PUT '/rest/user/test001',
##    Content_Type    => 'application/json',
##    Content         => \$content,
##);
##
##is($response->code, 200, 'Response code for PUT without nonce');
##diag Dumper($response->content);
##$response_hash = decode_json $response->content;
##
##is($response_hash->{code}, $API__ERROR__MISSING_NONCE, 'Internal response code for PUT without nonce');
##is($response_hash->{error}, 'One or more errors');

# Read the record so we can try some update tests.
$response = request(GET '/rest/user/test001',
    Content_Type    => 'application/json',
);

#diag Dumper($response);
$response_hash = decode_json $response->content;
#diag Dumper($response_hash);

is($response_hash->{errors}, undef, "There are no errors for GET");
if (not $response_hash->{errors}) {
}

# Try to delete the record without a nonce.
$content = {%{$response_hash->{data}}};     # A shallow copy
$response = request(DELETE '/rest/user/test001',
    Content_Type    => 'application/json',
    Content         => \$content,
);

# What happens if we try to change the key of the record (the uid)?
$content = encode_json {
    uid             => 'test002',
};

$response = request(PUT '/rest/user/test001',
    Content_Type    => 'application/json',
    Content         => \$content,
);

$response_hash = decode_json $response->content;

is(scalar(@{$response_hash->{errors}}), 1, 'Only one sub-error');

$sub_error = $response_hash->{errors}[0];
is($sub_error->{attribute}, 'uid', 'Sub error attribute');
is($sub_error->{value}, 'test001', 'Sub error value');
is($sub_error->{code}, $API__ERROR__CANNOT_MODIFY_KEY, 'Sub error code');

# Read the record back to get the nonce.
$response = request(GET '/rest/user/test001',
    Content_Type    => 'application/json',
);

$response_hash = decode_json $response->content;

# What happens if we try to create a record without a mandatory field?

$content = encode_json {
    uid             => 'test003',
    uid_number      => 11112222,
    gid_number      => 20,
#    surname         => 'Smith', # this is a mandatory field.
    full_name       => 'John Smith',
    employee_number => 'EU11112222',
    home_directory  => '/home/smith003',
    login_shell     => '/bin/csh',
};

$response = request(PUT '/rest/user/test003',
    Content_Type    => 'application/json',
    Content         => \$content,
);

diag $response->content;
$response_hash = decode_json $response->content;
is(scalar(@{$response_hash->{errors}}), 1, 'Only one sub-error');
$sub_error = $response_hash->{errors}[0];
is($sub_error->{attribute}, 'surname', 'Mandatory field surname is missing - attribute');
is($sub_error->{code}, $API__ERROR__MISSING_MANDATORY_FIELD, 'Mandatory field surname is missing - code');

done_testing;
exit;


