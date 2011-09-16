#!/home/docherti/perl5/perlbrew/perls/perl-5.8.9/bin/perl -w

use strict;
use warnings;

use Authen::Krb5;

my $auth_context = new Authen::Krb5::AuthContext;

print "hello world ($auth_context)\n";
1;

