#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin;
use FindBin::libs;
use Data::Dumper;
use Log::Log4perl;

use Nomura::DRAFT::SharedData::App::Control;
use Nomura::DRAFT::SharedData::App::Control::Thingy;
use Nomura::DRAFT::SharedData::Database::Backup;
use Nomura::DRAFT::Transport::Socket::Controller;
use Nomura::DRAFT::ControllerFactory;

Log::Log4perl::init("$FindBin::Bin/socket_controller_log4perl.conf");

my $log = Log::Log4perl->get_logger;

### Set up the transport (this might be best as a Factory at some point)
my $transport = Nomura::DRAFT::Transport::Socket::Controller->new({
    local_host      => 'lonlx20575',
    peer_port       => 51002,
    peer_address    => 'lonlx8001b16.lehman.com',
    dfa_state       => 'start',
});

### Set the shared data
my $thingy      = Nomura::DRAFT::SharedData::App::Control::Thingy->new({
    whatsit     => 456,
});

my $app_data = Nomura::DRAFT::SharedData::App::Control->new({
    app_name    => 'freddy',
    thingy      => $thingy,
    verbose     => 1,
    dry_run     => 1,
});

my $app_controller = Nomura::DRAFT::ControllerFactory->create('App::Control', {
    transport       => $transport,
    data            => $app_data,
    verbs           => [qw(start stop status)],
});

my $database_data = Nomura::DRAFT::SharedData::Database::Backup->new({
    database_name   => 'freddy',
    table_names     => [qw(foo bar bam)],
});

my $db_controller = Nomura::DRAFT::ControllerFactory->create('Database::Backup', {
    transport       => $transport,
    data            => $database_data,
    verbs           => [qw(backup restore)],
});

print STDERR "got here -1\n";

# Transport the data to the client and get the response
#
$transport->set_log_level('DEBUG','');
print STDERR "got here 0\n";

$transport->set_log_level('DEBUG','App::Control');
print STDERR "got here 1\n";

$transport->set_log_level('DEBUG','Database::Backup');

print STDERR "got here 2\n";

if ($app_controller->start) {
    $log->info("START success");
}
else {
    $log->error("START failure");
}

$db_controller->backup;

#print "DATA AFTER START: ".Dumper($app_controller->data);

# Obtain the log information from the transport layer.
$log->info("LOG DATA AFTER START\n".$transport->log_data);

$app_controller->data->dry_run(0);
if ($app_controller->stop) {
    $log->info("STOP success");
}
else {
    $log->error("STOP failure");
}

$db_controller->restore;

# Obtain the log information from the transport layer.
print "LOG DATA AFTER RESTORE\n".$transport->log_data;

$transport->quit;

#$app_controller->status;

print "DATA: ###\n".$app_controller->data->log_message."###\n";


1;

=head1 - an example

=begin html

<table>
  <tr>
    <td>hello</td>
    <td>hi</td>
  </tr>
  <tr>
    <td colspan="2">two colomns</td>
  </tr>
</table>

=end html

=cut
