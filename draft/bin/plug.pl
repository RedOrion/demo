#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Data::Dumper;

use Nomura::DRAFT::SharedData::App::Control;
use Nomura::DRAFT::Transport::Local::Controller;
use Nomura::DRAFT::ServerFactory;

### Set up the transport (this might be best as a Factory at some point)
my $transport = Nomura::DRAFT::Transport::Local::Controller->new;

### Set the shared data
my $shared_data = Nomura::DRAFT::SharedData::App::Control->new({
    app_name    => 'freddy',
    verbose     => 1,
    dry_run     => 1,
});

my $server = Nomura::DRAFT::ServerFactory->create('App::Control', {
    transport       => $transport,
    data            => $shared_data,
    methods         => [qw(start stop status)],
});

print "Server factory returned [$server]\n";
#$server->status;

print Dumper($server->data);

# Set the dry_run flag
$server->data->dry_run(1);

# Set some data in the (specific) shared data
$server->data->app_name('foo');

# Transport the data to the client and get the response
#
# NOTE: It would be cool if we could call $server->start here and for it
# to automatically call the client and get the response! (Java Beans?)
#
$server->start;
$server->stop;
$server->status;

print "DATA: ###\n".$server->data->log."###\n";

# COOL!

1;
