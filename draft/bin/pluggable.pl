#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Nomura::DRAFT::Server;

my $server = Nomura::DRAFT::Server->new;

my $os_to_plugin = {
    linux   => 'Linux',
};

my $os = $os_to_plugin->{$^O};

$server->test;
$server->_plugin_app_ns(['Nomura::DRAFT',"Nomura::DRAFT::$os",'Nomura::DRAFT::Generic']);

#$server->load_plugin('Server');
$server->load_plugin('App::Control');

$server->dry_run(1);
$server->name('foo');
$server->start;

1;
