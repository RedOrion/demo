#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Nomura::DRAFT::Transport::Client::DFA;

my $local_host  = 'lonlx20575';
my $local_port  = 55543;

my $dfa = Nomura::DRAFT::Transport::Client::DFA->new({
    dfa_state => 'start',
});

print "dfa = [$dfa]\n";

my $response = $dfa->request('HELLO');


1;
