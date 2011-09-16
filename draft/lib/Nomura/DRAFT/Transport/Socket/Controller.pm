package Nomura::DRAFT::Transport::Socket::Controller;

# A transport layer for talking to a remote host using a Socket
use Moose;
use Data::Dumper;
use IO::Socket::INET;
use Data::Serializer::Raw;
use Nomura::DRAFT::Agent;
use Log::Log4perl;

extends 'Nomura::DRAFT::Transport';

with 'MooseX::DFA::Simple';

has 'local_host'  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'peer_port'  => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
);

has 'peer_address'  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'socket' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_socket',
);

has 'controller' => (
    is          => 'rw',
    isa         => 'Nomura::DRAFT::Controller::Plugin',
);

has 'command' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'log_level' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'rec_data' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'rec_log' => (
    is          => 'rw',
    isa         => 'Str',
);

has 'log' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_log',
);

sub _build_log {
    my ($self) = @_;

    Log::Log4perl->get_logger( ref($self) );
}

sub _build_socket {
    my ($self) = @_;

#    print STDERR "PeerAddr = [".."] PeerPort =[".$self->peer_port."] PeerPort=[".$self->peer_port."]\n";
    my $socket = IO::Socket::INET->new(
        PeerAddr    => $self->peer_address,
        PeerPort    => $self->peer_port,
        Proto       => 'tcp',
    );
#    print STDERR "SOCKET:=[$socket] peer_addr=[".$self->peer_address."] peerport=[".$self->peer_port."]\n";
    return $socket;
}

sub _build_dfa_transitions {
    my ($self) = @_;

    my $transitions = {
        start => {
            get_ok_hello => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->dfa_input =~ /^OK HELLO$/; },
                state   => 'send_cmd',
            }),
        },
        send_cmd => {
            get_ok_cmd => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->dfa_input =~ /^OK COMMAND$/; },
                state   => 'send_data',
            }),
        },
        send_data => {
            get_ok_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->dfa_input =~ /^OK DATA$/; },
                state   => 'rec_resp',
                action  => sub { $self->rec_data(''); },
            }),
        },
        rec_resp => {
            get_response => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->dfa_input =~ /^RESPONSE$/; },
                state   => 'rec_data',
                action  => sub { $self->rec_data(''); },
            }),
        },
        rec_data => {
            get_more_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->_test_more_data(@_); },
                action  => sub { $self->_get_more_data(@_); },
                state   => 'rec_data',
            }),
            get_end_of_data => MooseX::DFA::Simple::Transition->new({
                test    => sub { not $self->_test_more_data(@_); },
                state   => 'done',
                action  => sub { $self->_response("OK RESPONSE\n"); },
            }),
        },
        log => {
            get_ok_hello => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->dfa_input =~ /^OK HELLO$/; },
                state   => 'rec_log',
            }),
        },
        rec_log => {
            get_more_log => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->_test_more_data(@_); },
                action  => sub { $self->_get_more_log(@_); },
                state   => 'rec_log',
            }),
            get_end_of_log => MooseX::DFA::Simple::Transition->new({
                test    => sub { not $self->_test_more_data(@_); },
                state   => 'done',
                action  => sub { $self->_response("OK LOG\n"); },
            }),
        },
        log_level => {
            get_ok_hello => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->dfa_input =~ /^OK HELLO$/; },
                state   => 'send_level',
            }),
        },
        send_level => {
            get_ok_log_level => MooseX::DFA::Simple::Transition->new({
                test    => sub { $self->dfa_input =~ /^OK LOG_LEVEL$/; },
                state   => 'done',
            }),
        },
    };
    return $transitions;
}

sub _build_dfa_states {
    my ($self) = @_;

    my $states = {
        start => {
            entry_action    => sub { $self->_send_hello; },
        },
        log => {
            entry_action    => sub { $self->_send_hello; },
        },
        log_level => {
            entry_action    => sub { $self->_send_hello; },
        },
        rec_log => {
            entry_action    => sub { $self->_response("LOG\n"); $self->rec_log('');},
        },
        send_cmd => {
            entry_action    => sub { $self->_send_cmd; },
        },
        send_data => {
            entry_action    => sub { $self->_send_data; },
        },
        rec_resp => {
        },
        rec_data => {
            entry_action    => sub { $self->rec_data(''); },
        },
        send_level => {
            entry_action    => sub { $self->_send_level; },
        },
        done => {
            entry_action    => sub { $self->_save_data; },
        },
    };
    return $states;
}

sub _response {
    my ($self, $response) = @_;

    if ($response ne '') {
        $self->log->debug("SEND: $response");
        my $socket = $self->socket;
        print $socket $response;
    }
    else {
#        print ">>>> new state [".$self->dfa_state."] no response\n";
    }
}

sub _send_hello {
    my ($self) = @_;

    my $response = 'HELLO '.$self->local_host."\n";
    $self->_response($response);
}

sub _send_cmd {
    my ($self) = @_;

    my ($plugin) = ref($self->controller) =~ /::Plugin::(.*)$/;
    $self->log->info("### send_cmd ### controller=[".$self->controller."] command=[".$plugin."]");


    my $command  = $self->command;
    my $response = "COMMAND $plugin->$command\n";
    $self->_response($response);
}

# Send the required log level
sub _send_level {
    my ($self) = @_;

    $self->_response("LOG_LEVEL ".$self->log_level."\n");
}

sub _send_data {
    my ($self) = @_;

    my $response = "DATA ".$self->controller->data->freeze."\n.\n";
    $self->_response($response);
}

sub _save_data {
    my ($self) = @_;

    if ($self->controller) {
        $self->log->debug("CONTROLLER=[".$self->controller."]");
        my ($plugin) = ref($self->controller) =~ /::Plugin::(.*)$/;
        my $class = "Nomura::DRAFT::SharedData::$plugin";
        eval "require $class";

        my $shared_data = $class->thaw($self->rec_data);
        $self->controller->data($shared_data);
    }
    $self->_response('');
}

# Determine if there is more data
#
sub _test_more_data {
    my ($self, $input) = @_;

    chomp $input;
    if ($input ne '.') {
        return 1;
    }
    return;
}

sub _get_more_data {
    my ($self, $input) = @_;

    $self->rec_data($self->rec_data . $input);
}

sub _get_more_log {
    my ($self, $input) = @_;

    $self->rec_log($self->rec_log . $input);
}

# execute state changes until 'done'
#
sub _execute {
    my ($self) = @_;

    my $socket = $self->socket;
$self->log->debug("socket = [$socket]");

    STATE:
    while (my $line = <$socket>) {
        $self->log->debug("RECEIVE: $line");
        $self->dfa_check_state($line);
        $self->log->debug("STATE: ".$self->dfa_state);
        last STATE if $self->dfa_state eq 'done';
    }
}

# Request the log data
#
sub log_data {
    my ($self) = @_;

    $self->dfa_state('log');
    $self->_execute;
    return $self->rec_log;
}


# Set the Agent log level
# e.g. $transport->set_log_level('DEBUG', 'Plugin::App')
#
sub set_log_level {
    my ($self, $level, $module) = @_;

    $self->log->debug("Set log level to $level $module");
    $self->log_level("$level $module");
    $self->dfa_state('log_level');


    $self->_execute;
}

# send the data
#
sub send {
    my ($self, $controller, $command) = @_;

    # Factor these out into the caller
    $self->controller($controller);
    $self->command($command);
    $self->dfa_state('start');
    $self->_execute;
    return $controller->data->status;
}

# implement this as a state with an entry action
#
sub quit {
    my ($self) = @_;

    my $socket = $self->socket;

    print $socket "QUIT\n";
}

no Moose;
1;

