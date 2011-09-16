#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Data::Serializer::Raw;

use Nomura::DRAFT::Plugin::Server::Serial;
use Nomura::DRAFT::Plugin::App::Control::SharedData;

my $shared = Nomura::DRAFT::Plugin::App::Control::SharedData->new({app_name => 'fumble'});
my $server = Nomura::DRAFT::Plugin::Server::Serial->new({shared => $shared});

print "Server = [$server]\n";

my $serializer = Data::Serializer::Raw->new(serializer => 'Data::Dumper');

my $string = $serializer->serialize($server);

print "serialized = [$string]\n";

my $thing = $serializer->deserialize($string);

print "deserialized = [$thing]\n";

print "thing = ".$thing->shared->app_name."\n";

1;
