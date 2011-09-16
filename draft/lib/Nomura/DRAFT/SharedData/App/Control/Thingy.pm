package Nomura::DRAFT::SharedData::App::Control::Thingy;
#
# Data shared between Client and Server
#
use Moose;
use MooseX::Storage;

with Storage('format' => 'JSON');

# Name of application
has 'whatsit'  => (
    is          => 'rw',
    isa         => 'Int',
#    required    => 1,
);


sub test {
    my ($self) = @_;

    print "I am here [".$self->whatsit."]\n";
}

1;


