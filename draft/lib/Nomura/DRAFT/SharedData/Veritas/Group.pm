package Nomura::DRAFT::SharedData::Veritas::Group;
#
# Data shared between Controller and Agent
#
use Moose;

# Bring in the data common to all SharedData objects
extends 'Nomura::DRAFT::SharedData';

# Veritas Group Name
has 'group_name'  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'hostname' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

1;


