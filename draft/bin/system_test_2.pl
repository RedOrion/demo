#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Data::Dumper;

open(PS, "./simple_io.pl |") or die "Failed $!\n";

print PS "FOO\n";

while (my $line = <PS>) {
    chomp $line;
    print "### [$line] ###\n";
}

