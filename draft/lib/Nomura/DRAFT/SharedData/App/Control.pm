package Nomura::DRAFT::SharedData::App::Control;
#
# Data shared between Client and Server
#
use Moose;

# Bring in the data common to all SharedData objects
extends 'Nomura::DRAFT::SharedData';

# Name of application
has 'app_name'  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'thingy' => (
    is          => 'rw',
    isa         => 'Nomura::DRAFT::SharedData::App::Control::Thingy',
    required    => 1,
);

sub test {
    my ($self) = @_;

    print "I am here [".$self->app_name."]\n";
}

1;


