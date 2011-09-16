package Nomura::DRAFT::Agent;

# A generic pluggable agent object

use Moose;

with 'MooseX::Object::Pluggable';

# Shared data
has 'data'  => (
    is          => 'rw',
    isa         => 'Nomura::DRAFT::SharedData',
    required    => 1,
);

has 'log' => (
    is          => 'ro',
    required    => 1,
);

1;

