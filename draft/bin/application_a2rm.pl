#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

# DEMO program to simulate an A2RM application running on two Data Centres

use FindBin;
use FindBin::libs;
use Data::Dumper;
use Log::Log4perl;

use Nomura::DRAFT::SharedData::System::Service;
use Nomura::DRAFT::Transport::Socket::Controller;
use Nomura::DRAFT::ServerFactory;

Log::Log4perl::init("$FindBin::Bin/socket_controller_log4perl.conf");

my $log = Log::Log4perl->get_logger;

# Config, hard coded for now but will eventually come from external source (yaml or A2RM itself)
my $config = {
    port            => 51000,
    local_host      => 'lonlx20575',
    dc1 => {
        hostname    => 'lonlx8001b07.lehman.com',
        service_1   => 'httpd',
        veritas_1   => {
            name    => 'EEULB007',
            host    => 'lonlx8001b07',
        },
    },
    dc2 => {
        hostname    => 'lonlx8001b16.lehman.com',
        service_1   => 'httpd',
        veritas_1   => {
            name    => 'EEULB007',
            host    => 'lonlx8001b16',
        },
    },
};

# Set up the transport to each of the servers
#
my $transport_dc1 = Nomura::DRAFT::Transport::Socket::Controller->new({
    local_host      => $config->{local_host},
    peer_port       => $config->{port},
    peer_address    => $config->{dc1}{hostname},
});
my $transport_dc2 = Nomura::DRAFT::Transport::Socket::Controller->new({
    local_host      => $config->{local_host},
    peer_port       => $config->{port},
    peer_address    => $config->{dc2}{hostname},
});

my $application_1 = Nomura::DRAFT::ApplicationFactory->create('A2RM', {
    service_1       => Nomura::DRAFT::ControllerFactory->create('System::Service', {
        transport       => $transport_dc1,
        data            => Nomura::DRAFT::SharedData::System::Service->new({
            service_name    => 'httpd',
        },
    },
    veritas_1       => Nomura::DRAFT::ControllerFactory->create('Veritas::Group', {
});




my $service_1 = Nomura::DRAFT::ServerFactory->create('System::Service', {
    transport       => $transport_dc1,



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
