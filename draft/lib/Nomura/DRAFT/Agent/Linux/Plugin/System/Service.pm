package Nomura::DRAFT::Agent::Linux::Plugin::System::Service;

# System services plugin

use Moose::Role;

with 'Nomura::DRAFT::System::Command';

sub start {
    my ($self) = @_;

    $self->log->info("Start Service [".$self->data->service_name."]");

    my $ret_status = $self->system_call('/sbin/service '.$self->data->service_name.' start');
    $self->log->debug("Return status = [$ret_status]");

    return $ret_status;
}

sub stop {
    my ($self) = @_;

    $self->log->info("Stop Service [".$self->data->service_name."]");

    my $ret_status = $self->system_call('/sbin/service '.$self->data->service_name.' stop');
    $self->log->debug("Return status = [$ret_status]");

    return $ret_status;
}


# Return the current status of the application.
# either 'running', 'stopped', or in the case of an error 'unknown'
#
sub status {
    my ($self) = @_;

    my $current_status = 'unknown';

    my $old_input_output = $self->data->input_output;
    $self->data->input_output('');

    $self->log->info("Status Service [".$self->data->service_name."]");

    my $ret_status = $self->system_call('/sbin/service '.$self->data->service_name.' status');
    $self->log->debug("Return status = [$ret_status]");
    if (not $ret_status) {
        ($current_status) = $self->data->input_output =~ /^OUT: httpd.* is (stopped|running).*$/m;
    }
    # append the new input-output data
    $self->data->input_output($old_input_output.$self->data->input_output);

    return $current_status;
}

1;

