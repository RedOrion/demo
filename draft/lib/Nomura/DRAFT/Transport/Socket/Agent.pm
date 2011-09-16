package Nomura::DRAFT::Transport::Socket::Agent;
#
# Deterministic Finite Automata (Finite State Machine) for the agent
#
use Moose;
use IO::Socket;
use DateTime;
use Parallel::ForkManager;
use Log::Log4perl;
use Log::Log4perl::Level;
use Data::Dumper;
use Data::Serializer::Raw;
use Nomura::DRAFT::Agent;

with 'MooseX::DFA::Simple';

has 'socket' => (
    is          => 'rw',
    isa         => 'IO::Socket::INET',
    required    => 1,
);

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

has 'log_data' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '',
);

sub _build_log {
    my ($self) = @_;

    my $log = Log::Log4perl->get_logger(ref $self);
    $log->debug("GOT LOGGER for [".ref $self."]");
    return $log;
}

sub _build_dfa_transitions {
    my ($self) = @_;

    my $transitions = {
        start => {
            get_hello => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_hello(@_); },
                state   => 'wait_cmd',
                action  => sub { $self->response("OK HELLO\n"); },
            }),
        },
        wait_cmd => {
            get_hello => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_hello(@_); },
                state   => 'wait_cmd',
                action  => sub { $self->response("OK HELLO\n"); },
            }),
            get_command => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_cmd(@_); },
                state   => 'rec_cmd',
                action  => sub { $self->response("OK COMMAND\n"); },
            }),
            get_quit => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_quit(@_); },
                state   => 'rec_quit',
                action  => sub { $self->response("OK QUIT\n"); },
            }),
            get_log => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_log(@_); },
                state   => 'do_log',
            }),
            get_level => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_log_level(@_); },
                action  => sub { $self->response("OK LOG_LEVEL\n"); },
                state   => 'wait_cmd',
            }),
        },
        rec_cmd => {
            get_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_data(@_); },
                state   => 'rec_data',
                action  => sub { $self->response(''); },
            }),
        },
        rec_data => {
            get_more_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_more_data(@_); },
                action  => sub { $self->response(''); },
                state   => 'rec_data',
            }),
            get_end_of_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_end_of_data(@_); },
                state   => 'do_cmd',
            }),
        },
        do_cmd => {
            get_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_response(@_); },
                state   => 'wait_cmd',
                action  => sub { $self->response(''); },
            }),
        },
        do_log => {
            get_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->test_ok_log(@_); },
                state   => 'wait_cmd',
                action  => sub { $self->response(''); },
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
        wait_cmd => {
        },
        rec_cmd => {
            entry_action    => sub {$self->data('');},
        },
        rec_data => {
        },
        do_cmd => {
            entry_action    => sub {$self->do_cmd;},
        },
        do_log => {
            entry_action    => sub {$self->do_log;},
        },
        rec_quit => {
        },
    };
    return $states;
}

# 'print' method for Log::Log4perl
#
sub print {
    my ($self, $msg) = @_;

    $self->log_data($self->log_data . $msg);
#    print "####LOG####\n$msg####END LOG####\n";
}

# Send the log file
#
sub do_log {
    my ($self) = @_;

    $self->response($self->log_data . ".\n");
}

# Do the command
#
sub do_cmd {
    my ($self) = @_;

    # Create a local object and deserialize the shared data
    my ($component,$command) = $self->command =~ /^(.*)-\>(.*)$/;
#    print "DO_CMD: component=[$component] command=[$command]\n";
    $self->log->debug("Do command [$command] with component [$component]");

    my $class = "Nomura::DRAFT::SharedData::$component";
    eval "require $class";

    my $shared_data = $class->thaw($self->data);

#    print "SHARED DATA:\n".Dumper($shared_data);

    ### NOTE ### we should check that the data ISA 'Nomura::DRAFT::SharedData'

    $self->log->error("DO_CMD: [$component.$command]");
    my $log = Log::Log4perl->get_logger("$component.$command");

#    $log->error("TEST TEST TEST");

    my $agent = Nomura::DRAFT::Agent->new({
        data    => $shared_data,
        log     => $log,
    });
#    print "agent = [$agent]\n";

    # assume for now that the operating system is Linux
    my $os = 'Linux';

    $agent->_plugin_app_ns(["Nomura::DRAFT::Agent::$os"]);

#    print "agent after plugin = [$agent] component = [$component]\n";

#    print "plugin_ns = [".$agent->_plugin_ns."]\n";

    $agent->load_plugin($component);

#    print "do_cmd: agent=(".$agent.") command=($command)\n";

    # should do a 'has' here to ensure the component has this method
    # if ($agent->has_method($command)) { # or something like it...
    #
    $agent->data->status($agent->$command);

#    $agent->data->test;

    # Now we should be sending the data back and waiting for another command.

    # Freeze the data for transfer
    my $response = "OK DATA\nRESPONSE\n".$agent->data->freeze."\n.\n";
    $self->response($response);
#    print "SENDING RESPONSE ".$response;

#    print Dumper($agent);
}

# Determine if it is the 'HELLO' command, in which case
# store the hostname of the caller
#
sub test_hello {
    my ($self, $input) = @_;

#    $self->log->debug("Got to test_hello");
#    print "test_hello: self=[$self] input=[$input]\n";

    if (my ($hostname) = $input =~ /^HELLO(.*)$/) {
        $self->server($hostname);
        return 1;
    }
    return;
}

# Determine if it is the 'OK RESPONSE' command
#
sub test_response {
    my ($self, $input) = @_;

    if ($input =~ /^OK RESPONSE$/) {
        return 1;
    }
    return;
}

# Determine if it is the 'OK LOG' command
#
sub test_ok_log {
    my ($self, $input) = @_;

    if ($input =~ /^OK LOG$/) {
        return 1;
    }
    return;
}

# Determine if it is the 'QUIT' command
#
sub test_quit {
    my ($self, $input) = @_;

    if ($input =~ /^QUIT$/) {
        return 1;
    }
    return;
}

# Determine if it is the 'LOG' command
#
sub test_log {
    my ($self, $input) = @_;

    if ($input =~ /^LOG$/) {
        return 1;
    }
    return;
}

# Determine if it is the 'LOG_LEVEL' command
#
sub test_log_level {
    my ($self, $input) = @_;

#    $self->log->fatal("TEST_LOG_LEVEL input=[$input]");
    if (my ($level,$category) = $input =~ /^LOG_LEVEL\W*(DEBUG|INFO|WARN|ERROR|FATAL)\W*(.*)$/) {
#        $self->log->debug("LOG_LEVEL [$level] category [$category]");
        my $logger = Log::Log4perl->get_logger("$category");
        $logger->level($level);
        return 1;
    }
    else {
        $self->log->error("LOG_LEVEL FAILURE [$input]");
    }
    return;
}

# Determine if it is the 'COMMAND' command, in which case
# store Command requested
#
sub test_cmd {
    my ($self, $input) = @_;

    if (my ($command) = $input =~ /^COMMAND(.*)$/) {
        $command =~ s/^\W*(.*)\W*$/$1/;
        $self->command($command);
        return 1;
    }
    return;
}

# Determine if it is the 'DATA' command
#
sub test_data {
    my ($self, $input) = @_;

    if (my ($data) = $input =~ /^DATA(.*)$/) {

        $self->data($data);
        return 1;
    }
    return;
}

# Determine if there is more data
#
sub test_more_data {
    my ($self, $input) = @_;

#    print "test_more_data: self=[$self] input=[$input]\n";

    chomp $input;
    if ($input ne '.') {
        # This might be better if we introduce the concept of a transition action
        $self->data($self->data . " $input");
        return 1;
    }
    return;
}

# Test for the end of the data
#
sub test_end_of_data {
    my ($self, $input) = @_;

#    print "test_end_of_data: self=[$self] input=[$input]\n";

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

    $self->log->debug("REQUEST: $line");

    return $self->dfa_check_state($line);
}

no Moose;
1;
