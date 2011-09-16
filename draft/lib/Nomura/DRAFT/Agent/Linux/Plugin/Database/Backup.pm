package Nomura::DRAFT::Agent::Linux::Plugin::Database::Backup;

#
# Plugin to control applications, start/stop/status etc.
#
use Data::Dumper;
use Moose::Role;

with 'Nomura::DRAFT::System::Command';

sub backup {
    my ($self) = @_;

    $self->log->fatal("BACKUP THE DATABASE");
    return 1;
}

sub restore {
    my ($self) = @_;

    $self->log->fatal("RESTORE THE DATABASE");
    return 0;
}

1;

