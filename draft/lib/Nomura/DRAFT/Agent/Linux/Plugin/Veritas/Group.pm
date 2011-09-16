package Nomura::DRAFT::Agent::Linux::Plugin::Veritas::Group;

# System services plugin

use Moose::Role;

with 'Nomura::DRAFT::System::Command';

sub online {
    my ($self) = @_;

    $self->log->info("online Veritas Group [".$self->data->group_name."]");

    my $ret_status = $self->system_call('/opt/VRTS/bin/hagrp -online '.$self->data->group_name.' -sys '.$self->data->hostname);
    $self->log->debug("Return status = [$ret_status]");

    return $ret_status;
}

sub offline {
    my ($self) = @_;

    $self->log->info("offline Veritas Group [".$self->data->group_name."]");

    my $ret_status = $self->system_call('/opt/VRTS/bin/hagrp -offline '.$self->data->group_name.' -sys '.$self->data->hostname);
    $self->log->debug("Return status = [$ret_status]");

    return $ret_status;
}


# Return the current status of the group.
#
sub status {
    my ($self) = @_;

    my $current_status = 'unknown';

    my $old_input_output = $self->data->input_output;
    $self->data->input_output('');

    $self->log->info("Veritas Group Name [".$self->data->group_name."]");

    my $ret_status = $self->system_call('/opt/VRTS/bin/hagrp -state '.$self->data->group_name.' -sys '.$self->data->hostname);

    $self->log->debug("Return status = [$ret_status]");
    if (not $ret_status) {
        $self->log->debug("raw input_output = [".$self->data->input_output."]");
        ($current_status) = $self->data->input_output =~ /^OUT: (.*)$/m;
    }
    # append the new input-output data
    $self->data->input_output($old_input_output.$self->data->input_output);
    $self->log->info("Veritas Returns Status [$current_status]");

    return $current_status;
}

1;

