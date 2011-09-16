#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use FindBin;
use Data::Dumper;
use Parallel::ForkManager;
use Log::Log4perl;

use Nomura::DRAFT::Transport::Socket::Agent;

my $log4perl_file   = "$FindBin::Bin/socket_agent.log4perl.conf";
my $local_port  = 51002;

my $socket = IO::Socket::INET->new(
    LocalPort   => $local_port,
    Proto       => 'tcp',
    Listen      => 1,
    Reuse       => 1,
);

die "Could not create socket: $!\n" unless $socket;

my $pm              = new Parallel::ForkManager(5);
Log::Log4perl::init($log4perl_file);

# Get the root logger (which we add to the finite state machines)
my $log = Log::Log4perl->get_logger('');
$log->debug("HELLO WORLD");

my $layout      = Log::Log4perl::Layout::PatternLayout->new(
    "AGENT %c %p{1} %M #%L - %m%n",
);

ACCEPT:
while (1) {
    my ($new_socket, $peer_addr) = $socket->accept();

    if ($pm->start) {
        # parent
        print "Parent\n";
        next ACCEPT;
    }
    # child
    print "Child. socket = [$new_socket]\n";

    # Create a new Finite State Machine
    my $transport = Nomura::DRAFT::Transport::Socket::Agent->new({
        socket      => $new_socket,
        dfa_state   => 'start',
        log         => $log,
    });

    # Add a log dispatch appender to the root logger
    my $appender    = Log::Log4perl::Appender->new(
        "Log::Dispatch::Handle",
        name        => 'agent',
        handle      => $transport,
    );
    $appender->layout($layout);
    $log->add_appender($appender);

    $log->info("MAIN: Accepting input");

    # Keep processing until the Controller drops the connection
    LINE:
    while (my $line = <$new_socket>) {
        chomp $line;
        $log->debug("MAIN: <<<< State     ".$transport->dfa_state." RECEIVE: $line");

        $transport->request($line);
        if ($transport->response eq '') {
            $log->debug("MAIN: >>> NEW State: ".$transport->dfa_state." no response");
        }
        else {
            $log->debug("MAIN: >>> NEW State: ".$transport->dfa_state." SEND: ".$transport->response);
            print $new_socket $transport->response;
        }
        last LINE if $transport->dfa_state eq "rec_quit";
    }
    print "Child. finish\n";
    $pm->finish;
}

1;
