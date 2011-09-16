package Nomura::DRAFT::SharedData::Database::Backup;
#
# Data shared between Client and Server
#
use Moose;

# Bring in the data common to all SharedData objects
extends 'Nomura::DRAFT::SharedData';

# Name of database
has 'database_name'  => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

# Name of tables
has 'table_names'  => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
);

1;


