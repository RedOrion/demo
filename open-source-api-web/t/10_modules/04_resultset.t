#!/usr/bin/env perl

# Test for calculating nonce

use strict;
use warnings;
use Test::More;
use Test::Exception;
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

my $rs = Nomura::EPS::NS::API::Middleware::ResultSet->new({
   middleware => $middleware,
});

isa_ok($rs, 'Nomura::EPS::NS::API::Middleware::ResultSet');


# create some test data
# scalar data
my $scalar_data = ['testuser01','John Smith','John','Smith','/home/jsmith','/bin/bash','20','AP007'];
my $scalar_reduced_data = ['testuser01','John Smith','John','Smith','/home/jsmith','/bin/bash'];
my $scalar_more_data = ['testuser01','John Smith','John','Smith','/home/jsmith','/bin/bash','20','AP007','3212','unix'];

# array ref data
my $arry_ref_data = ['testuser01','John Smith',['John','Smith','/home/jsmith'],'/bin/bash','20','AP007'];
# hash ref data
my $hash_ref_data = ['testuser01','John Smith',{'firstname' => 'John', 'surname' => 'Smith'},'/home/jsmith','/bin/bash','20','AP007'];

# get the nonce values
my $nonce_scalar = $rs->_create_nonce($scalar_data); 
my $nonce_arr_ref = $rs->_create_nonce($arry_ref_data); 

# check if nonce value for scalar and array ref do not match
isnt($rs->_create_nonce($scalar_data), $rs->_create_nonce($arry_ref_data), "Nonce for scalar and array ref do not match" );

# check if nonce died on hash ref
dies_ok { $rs->_create_nonce($hash_ref_data) } 'Hash ref encountered';

# update the scalar data values 
@$scalar_data[2] = 'James';
@$scalar_data[6] = '30';

# re calculate nonce for updated data
my $nonce_updated_scalar = $rs->_create_nonce($scalar_data);

# check nonce after updating of data
isnt($nonce_scalar, $nonce_updated_scalar, "Nonce changed after data update");

# check nonce with less values against teh original values
isnt($rs->_create_nonce($scalar_data),$rs->_create_nonce($scalar_reduced_data), "Nonce with less number of values");

# check nonce with more values against the original values
isnt($rs->_create_nonce($scalar_data),$rs->_create_nonce($scalar_more_data), "Nonce with more number of values");

# check nonce if data is empty
isnt($rs->_create_nonce($scalar_data),$rs->_create_nonce([]), "Nonce for empty values");



done_testing();
