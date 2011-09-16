package Nomura::DRAFT::Transport::Local::Controller;

# A transport layer for talking to the local host
use Moose;
use Data::Dumper;

use Nomura::DRAFT::Agent;

extends 'Nomura::DRAFT::Transport';

my $os_to_plugin = {
    linux   => 'Linux',
};

# send the data
#
sub send {
    my ($self, $controller, $command) = @_;

    # Get the plugin name
    my ($plugin) = ref($controller) =~ /::Plugin::(.*)$/;
    my $os = $os_to_plugin->{$^O} || $^O;
    print "transport controller=[".ref($controller)."] command=[$command] plugin=[$plugin] os=[$os]\n";

    # Create a pluggable agent
    my $agent = Nomura::DRAFT::Agent->new({
        data    => $controller->data,
    });

    # Specify the plugin directories
    $agent->_plugin_app_ns(["Nomura::DRAFT::Agent::$os","Nomura::DRAFT::Agent::Generic"]);
    # Load the plugin
    $agent->load_plugin($plugin);

    # Execute the command
    $agent->$command;

    # Return the data
    $controller->data($agent->data);

}

1;

