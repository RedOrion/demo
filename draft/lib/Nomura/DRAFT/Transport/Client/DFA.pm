package Nomura::DRAFT::Transport::Client::DFA;
#
# Deterministic Finite Automata (Finite State Machine) for the client
#
use Moose;
use IO::Socket;
use DateTime;
use Parallel::ForkManager;
use Log::Log4perl;
use Data::Dumper;
use Data::Serializer::Raw;
use Nomura::DRAFT::Client;

with 'MooseX::DFA::Simple';

has 'response' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'log' => (
    is          => 'rw',
    lazy_build  => 1,
    builder     => '_build_log',
);

has 'server' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'command' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'data' => (
    is          => 'rw',
    isa         => 'Str',
);

sub _build_log {
    my ($self) = @_;

    return Log::Log4perl->get_logger('Nomura::DRAFT::Transport::Client::DFA');
}

sub _build_dfa_transitions {
    my ($self) = @_;

    my $transitions = {
        start => {
            get_hello => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_hello(@_); },
                state   => 'rec_hello',
            }),
        },
        rec_hello => {
            get_command => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_command(@_); },
                state   => 'rec_command',
            }),
        },
        rec_command => {
            get_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_data(@_); },
                state   => 'rec_data',
            }),
        },
        rec_data => {
            get_more_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_more_data(@_); },
                state   => 'rec_data',
            }),
            get_end_of_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_end_of_data(@_); },
                state   => 'do_command',
            }),
        },
    };
    return $transitions;
}

sub _build_dfa_states {
    my ($self) = @_;

    my $states = {
        start => {
        },
        rec_hello => {
            entry_action    => sub {print "OK HELLO\n";},
        },
        rec_command => {
            entry_action    => sub {print "OK COMMAND\n";},
        },
        do_command => {
            entry_action    => sub {$self->do_command;},
        },
    };
    return $states;
}

# Do the command
#
sub do_command {
    my ($self) = @_;

    # Create a local object and deserialize the shared data
    # For now, just assume that the local file system is Unix.

    my ($component,$command) = $self->command =~ /^(.*)-\>(.*)$/;
    print "DO_COMMAND: component=[$component] command=[$command]\n";

    my $serializer  = Data::Serializer::Raw->new(serializer => 'Data::Dumper');
    my $shared_data = $serializer->deserialize($self->data);

    my $client = Nomura::DRAFT::Client->new({
        shared  => $shared_data,
    });
    print "client = [$client]\n";

    my $os = 'Linux';

    $client->_plugin_app_ns(['Nomura::DRAFT',"Nomura::DRAFT::$os",'Nomura::DRAFT::Generic']);

    print "client after plugin = [$client] component = [$component]\n";

    print "plugin_ns = [".$client->_plugin_ns."]\n";




    $client->load_plugin($component);

    print "do_command: client=($client)\n";
    print Dumper($client);
}

# Determine if it is the 'HELLO' commaned, in which case
# store the hostname of the caller
#
sub test_hello {
    my ($self, $input) = @_;

    print "test_hello: self=[$self] input=[$input]\n";

    if (my ($hostname) = $input =~ /^HELLO(.*)$/) {
        $self->server($hostname);
        return 1;
    }
    return;
}

# Determine if it is the 'COMMAND' command, in which case
# store Command requested
#
sub test_command {
    my ($self, $input) = @_;

    print "test_command: self=[$self] input=[$input]\n";

    if (my ($command) = $input =~ /^COMMAND(.*)$/) {
        $command =~ s/^\W*(.*)\W*$/$1/;
        print "TEST_COMMAND: command=[$command]\n";
        $self->command($command);
        return 1;
    }
    return;
}

# Determine if it is the 'DATA' command
#
sub test_data {
    my ($self, $input) = @_;

    print "test_data: self=[$self] input=[$input]\n";

    if (my ($data) = $input =~ /^DATA(.*)$/) {
        print "DATA=($data)\n";

        $self->data($data);
        return 1;
    }
    return;
}

# Determine if there is more data
#
sub test_more_data {
    my ($self, $input) = @_;

    print "test_more_data: self=[$self] input=[$input]\n";

    chomp $input;
    if ($input ne '.') {
        $self->data($self->data . " $input");
        return 1;
    }
    return;
}

# Test for the end of the data
#
sub test_end_of_data {
    my ($self, $input) = @_;

    print "test_end_of_data: self=[$self] input=[$input]\n";

    chomp $input;
    if ($input eq '.') {
        return 1;
    }
    return;
}

# Process the request
#
sub request {
    my ($self, $line) = @_;

    return $self->dfa_check_state($line);
}

1;
