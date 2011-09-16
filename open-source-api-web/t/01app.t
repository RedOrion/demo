#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Nomura::EPS::NS::API::Web';

ok( request('/pod')->is_success, 'Request should succeed' );

done_testing();
