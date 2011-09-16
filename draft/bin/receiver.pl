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

my $new_socket  = $socket->accept();
my $pm          = new Parallel::ForkManager(30);
my $child_id    = 0;

SOCKET:
while (my $line = <$new_socket>) {
    chomp $line;
    print "Accept line [$line]\n";
    my $pid = $pm->start and next SOCKET;
    $child_id++;

    # Child process code
    for my $repeat (1..20) {
        print $child_id.": $repeat - $line\n";
        sleep 2;
    }
    $pm->finish;
}
close($socket);

1;
