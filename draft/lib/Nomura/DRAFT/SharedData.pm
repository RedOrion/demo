package Nomura::DRAFT::SharedData;

use Moose;
use MooseX::Storage;

with Storage('format' => 'JSON');

has 'dry_run'  => (
    is          => 'rw',
    isa         => 'Int',
);

has 'status' => (
    is          => 'rw',
#    isa         => 'Bool',
    default     => 0,
);

has 'log_message'       => (
    is          => 'rw',
    isa         => 'Str',
    default     => '',
);

has 'input_output' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '',
);

no Moose;
1;

