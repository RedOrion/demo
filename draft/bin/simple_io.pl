#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

#{
#    my $ofh = select STDOUT;
#    $| = 1;
#    select $ofh;
#}
#{
#    my $ofh = select INPUT;
#    $| = 1;
#    select $ofh;
#}

print STDOUT "Line one\n";
print STDOUT "Line two. now give me some input: ";
#my $input = <STDIN>;
my $input = 'test';
chomp $input;
print STDOUT "Line three. input was [$input]\n";

