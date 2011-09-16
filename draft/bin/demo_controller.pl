#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin;
use FindBin::libs;
use Data::Dumper;
use Log::Log4perl;

use Nomura::DRAFT::SharedData::System::Service;
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

my $app_data = Nomura::DRAFT::SharedData::System::Service->new({
    service_name    => 'httpd',
    dry_run         => 0,
});

my $sys_controller = Nomura::DRAFT::ServerFactory->create('System::Service', {
    transport       => $transport,
    data            => $app_data,
    verbs           => [qw(start stop status)],
});

# Transport the data to the client and get the response
#
$transport->set_log_level('FATAL','');
$transport->set_log_level('DEBUG','System::Service');

#my $status = $sys_controller->status;
#
#if ($status) {
#    $log->info("STATUS failure [$status]");
#}
#else {
#    $log->error("STATUS success");
#}
print "#####################\n";

my $current_status = $sys_controller->status;
print "CURRENT STATUS IS [$current_status]\n";

if ($current_status eq 'running') {
    print "Attempting to stop service\n";
    $sys_controller->stop;
    sleep 3;
    $current_status = $sys_controller->status;
}
elsif ($current_status eq 'stopped') {
    print "Attempting to start service\n";
    $sys_controller->start;
    sleep 3;
    $current_status = $sys_controller->status;
}
else {
    print "FATAL: current running status is 'unknown'\n";
}

if ($current_status eq 'running') {
    print "NEW status is running\n";
}
elsif ($current_status eq 'stopped') {
    print "NEW status is stopped\n";
}
else {
    print "FATAL: current running status is [$current_status]\n";
}

print "#####################\n";

# Obtain the log information from the transport layer.
#print "LOG DATA AFTER STATUS\n".$transport->log_data;
print "INPUT-OUTPUT\n".$sys_controller->data->input_output;
print "\n\n\n\n\n";
$transport->quit;

#print "DATA: ###\n".$sys_controller->data->log_message."###\n";


1;
