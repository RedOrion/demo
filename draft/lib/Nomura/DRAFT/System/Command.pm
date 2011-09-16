package Nomura::DRAFT::System::Command;

use Moose::Role;
use System::Command;

sub system_call {
    my ($self, $cmd) = @_;

    $self->data->input_output("IN : $cmd\n");
    my $status = 0;

    if ($self->data->dry_run) {
        $self->data->input_output($self->data->input_output . "OUT: (dry run, no output)\n");

    }
    else {
        my $cmd = System::Command->new($cmd);

        while (my $line = $cmd->stdout->getline) {
            $self->data->input_output($self->data->input_output . "OUT: $line");
        }
        $status = $cmd->exit || 0;
        if ($cmd->core) {
            $self->log->error("Core dump");
        }
        if ($cmd->signal) {
            $self->log->error("Signal [".$cmd->signal."]");
        }
    }
    return $status;
}

1;
