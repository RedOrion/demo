#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use IO::Socket;
use Parallel::ForkManager;

my $local_host  = 'lonlx20575';
my $local_port  = 55543;

my $socket = IO::Socket::INET->new(
    LocalHost   => $local_host,
    LocalPort   => $local_port,
    Proto       => 'tcp',
    Listen      => 1,
    Reuse       => 1,
);

die "Could not create socket: $!\n" unless $socket;

my $pm          = new Parallel::ForkManager(30);
my $child_id    = 0;

SOCKET:
while (my $new_socket = $socket->accept()) {
    print "Accepted a connection\n";

    if ($pm->start) {
        # parent
        print "Parent\n";
    }
    else {
        # child
        $child_id++;
        print "Child $child_id\n";
        while (my $line = <$new_socket>) {
            chomp $line;
            for my $iteration (1..5) {
                print "   $child_id: $iteration - $line\n";
                sleep 5;
            }
        }
        $pm->finish;
    }
    print "end of parent\n";
}

1;
