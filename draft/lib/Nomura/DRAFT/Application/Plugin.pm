package Nomura::DRAFT::Application::Plugin;
#
# Generic Application attributes for a plugin
#
use Moose;
use Log::Log4perl;

has 'log' => (
    is          => 'rw',
    lazy_build  => 1,
    builder     => '_build_log',
);

sub _build_log {
    my ($self) = @_;

    Log::Log4perl->get_logger( ref($self) );
}

1;
