package Nomura::DRAFT::SharedData::System::Service;
#
# Data shared between Client and Server
#
use Moose;

# Bring in the data common to all SharedData objects
extends 'Nomura::DRAFT::SharedData';

# Name of application
has 'service_name'  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

1;


