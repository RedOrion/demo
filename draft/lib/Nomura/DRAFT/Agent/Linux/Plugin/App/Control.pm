package Nomura::DRAFT::Agent::Linux::Plugin::App::Control;

#
# Plugin to control applications, start/stop/status etc.
#
use Data::Dumper;
use Moose::Role;

with 'Nomura::DRAFT::System::Command';

sub start {
    my ($self) = @_;

    $self->data->thingy->whatsit(666);
    $self->log->fatal("THIS IS THE START");

    $self->system_call('/etc/init.d/'.$self->data->app_name.' start');

    return 1;
}

sub stop {
    my ($self) = @_;

    $self->data->thingy->whatsit(111);
    $self->log->fatal("THIS IS THE END");

    $self->system_call('/etc/init.d/'.$self->data->app_name.' stop');
    return 0;
}

sub status {
    my ($self) = @_;

    $self->log->debug("THIS IS THE STATUS");

    return;
}

1;

