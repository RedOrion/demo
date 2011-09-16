#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin;
use FindBin::libs;
use Data::Dumper;
use Log::Log4perl;

use Nomura::DRAFT::SharedData::Veritas::Group;
use Nomura::DRAFT::Transport::Socket::Controller;
use Nomura::DRAFT::ServerFactory;

Log::Log4perl::init("$FindBin::Bin/socket_controller_log4perl.conf");

my $log = Log::Log4perl->get_logger;

### Set up the transport (this might be best as a Factory at some point)
my $transport = Nomura::DRAFT::Transport::Socket::Controller->new({
    local_host      => 'lonlx20575',
    peer_port       => 51000,
    peer_address    => 'lonlx8001b16.lehman.com',
    dfa_state       => 'start',
});

my $app_data = Nomura::DRAFT::SharedData::Veritas::Group->new({
    group_name      => 'EEULB007',
    hostname        => 'lonlx8001b16',
    dry_run         => 0,
});

my $veritas_group = Nomura::DRAFT::ServerFactory->create('Veritas::Group', {
    transport       => $transport,
    data            => $app_data,
    verbs           => [qw(online offline status)],
});

$transport->set_log_level('FATAL','');
$transport->set_log_level('DEBUG','Veritas::Group');

my $status = $veritas_group->status;
print "######################\n";
print "current status is [$status]\n";
if ($status eq 'ONLINE') {
    print "Setting the group OFFLINE\n";
    $veritas_group->offline;
    while ($status ne 'OFFLINE') {
        sleep 10;
        $status = $veritas_group->status;
        print "    current status is $status\n";
    }
}
else {
    print "Setting the group ONLINE\n";
    $veritas_group->online;
    while ($status ne 'ONLINE') {
        sleep 10;
        $status = $veritas_group->status;
        print "    current status is $status\n";
    }
}
#print "INPUT-OUTPUT\n".$veritas_group->data->input_output;

print "######################\n\n\n\n\n";

$transport->quit;

1;
