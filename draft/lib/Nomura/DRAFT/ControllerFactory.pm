package Nomura::DRAFT::ControllerFactory;

# Create an instance of a Plugin

use MooseX::AbstractFactory;
use Carp;

# Role(s) that define what the implementations should implement
#implementation_does         [];

implementation_class_via    sub { 'Nomura::DRAFT::Controller::Plugin::' . shift };

1;
