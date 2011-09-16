package Nomura::DRAFT::Application::Plugin::A2RM;
#
# Application Plugin
#
use Moose;

extends 'Nomura::DRAFT::Application::Plugin';

has 'service_1' => (
    is          => 'rw',
    isa         => 'Nomura::DRAFT::Controller::Plugin::App::Control',
    required    => 1,
);

# Take on-line
#

1;
