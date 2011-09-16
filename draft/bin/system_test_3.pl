#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Data::Dumper;

use Sys::Cmd;

my @cmd = ('./simple_io.pl');
my $proc = Sys::Cmd::run(@cmd);

    $proc->stdin->print("thanks\n");
while (my $line = $proc->stdout->getline) {
    $proc->stdin->print("thanks\n");
    print "GOT LINE: $line";
}
$proc->close;

