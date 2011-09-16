#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use IO::Socket::INET;

my $peer_address    = 'lonlx20575';
my $peer_port       = 55543;

my $socket = IO::Socket::INET->new(
    PeerAddr    => $peer_address,
    PeerPort    => $peer_port,
    Proto       => 'tcp',
);

die "Could not create socket: $!\n" unless $socket;

print $socket "Hello World\n";
LINE:
while (my $line = <$socket>) {
    print $line;
    chomp $line;
    if ($line =~ m/^DONE/) {
        print "ALL DONE!!!\n";
        last LINE;
    }
}

#sleep 10;
#print $socket "HELLO AGAIN!!!\n";



close($socket);

1;
