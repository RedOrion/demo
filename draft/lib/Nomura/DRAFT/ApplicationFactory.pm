package Nomura::DRAFT::ApplicationFactory;

# Create an instance of an Application Plugin

use MooseX::AbstractFactory;
use Carp;

# Role(s) that define what the implementations should implement
#implementation_does         [];

implementation_class_via    sub { 'Nomura::DRAFT::Application::Plugin::' . shift };

1;
