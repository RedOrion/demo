#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Nomura::DRAFT::Transport::Client::DFA;
use Nomura::DRAFT::Plugin::App::Control;
use Data::Serializer::Raw;

my $state;
my $dfa = Nomura::DRAFT::Transport::Client::DFA->new({
    dfa_state => 'start',
});

$dfa->dfa_check_state('HELLO lonlx20575');
check_result($dfa, 'rec_hello');

my $shared_data = Nomura::DRAFT::Plugin::App::Control::SharedData->new({
    app_name    => 'freddy',
});

my $server = Nomura::DRAFT::Plugin::App::Control->new({
    shared      => $shared_data,
});

$dfa->dfa_check_state('COMMAND App::Control->start');
check_result($dfa, 'rec_command');

my $serializer = Data::Serializer::Raw->new(serializer => 'Data::Dumper');
my $string = $serializer->serialize($shared_data);

$dfa->dfa_check_state('DATA');
check_result($dfa, 'rec_data');

$dfa->dfa_check_state($string);
check_result($dfa, 'rec_data');

$dfa->dfa_check_state('.');
check_result($dfa, 'do_command');

print "CHECK: state     = ".$dfa->dfa_state."\n";
print "CHECK: server    = ".$dfa->server."\n";
print "CHECK: command   = ".$dfa->command."\n";
print "CHECK: data      = ".$dfa->data."\n";


sub check_result {
    my ($dfa, $state) = @_;

    print "STATE: - expect = ($state) actual= #####(".$dfa->dfa_state.")#####\n";
    die if ($state ne $dfa->dfa_state);
}

1;
