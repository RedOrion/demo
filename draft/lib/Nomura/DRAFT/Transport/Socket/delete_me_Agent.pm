package Nomura::DRAFT::Transport::Socket::Agent;
#
# Communication Transport layer for Agent
# It will spawn Finite State Machines to handle each incoming connection
#
use Moose;
use IO::Socket;
use DateTime;
use Parallel::ForkManager;

has 'socket' => (
    is          => 'rw',
    isa         => 'IO::Socket::INET',
    required    => 1,
    lazy_build  => 1,
    builder     => '_build_socket',
);

has 'local_host' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has 'local_port' => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
);

has 'forks' => (
    is          => 'ro',
    isa         => 'Int',
    default     => 30,
);

# Lazy builder for socket
sub _build_socket {
    my ($self) = @_;

    my $socket = IO::Socket::INET->new(
        LocalHost   => $self->local_host,
        LocalPort   => $self->local_port,
        Proto       => 'tcp',
        Listen      => 1,
        Reuse       => 1,
    );
    return $socket;
}

# Listen on the port and accept commands
sub listen {
    my ($self) = @_;

    my $pm = new Parallel::ForkManager($self->forks);

    while (1) {
        my ($new_socket, $peer_addr) = $self->socket->accept();
        my $now = DateTime->now;
        print "Accepted a connection at $now\n";

        if ($pm->start) {
            # parent
            print "Parent\n";
        }
        else {
            # child
            # Create a new Finite State Machine
            my $dfa = Nomura::DRAFT::Transport::Socket::Agent::DFA->new({
                socket      => $new_socket,
            });

            LINE:
            while (my $line = <$new_socket>) {
                chomp $line;
                if ($dfa->request($line)) {
                    # continue processing
                    print $new_socket $dfa->response;
                }
                else {
                    # processing end
                    last LINE;
                }
            }

            print "DONE\n";
            $pm->finish;
        }
        print "end of parent\n";
    }
}
1;
