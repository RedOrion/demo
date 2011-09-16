#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Nomura::DRAFT::Transport::Client;

my $local_host  = 'lonlx20575';
my $local_port  = 55543;

my $client = Nomura::DRAFT::Transport::Client->new(
    local_host  => $local_host,
    local_port  => $local_port,
);

die "Could not create client: $!\n" unless $client;

$client->listen;

1;
