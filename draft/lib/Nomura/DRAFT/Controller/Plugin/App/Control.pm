package Nomura::DRAFT::Controller::Plugin::App::Control;
#
# Application Control Server Plugin
#
use Moose;

extends 'Nomura::DRAFT::Controller::Plugin';

sub usage {
    my ($self) = @_;

    print "USAGE: app__control --app_name <application name> <command>\n";
    print "  e.g. app__control --app_name my_app start\n";
    print "  shared data\n";
    print "    application name: ".$self->data->app_name."\n";
}

1;
