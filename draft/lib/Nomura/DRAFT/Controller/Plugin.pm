package Nomura::DRAFT::Controller::Plugin;
#
# Generic Server verbs and attributes for a plugin
#
use Moose;
use Carp;
use Data::Dumper;
use Log::Log4perl;

# Tell the plugin which data is shared between the server and the client
has 'data' => (
    is          => 'rw',
    isa         => 'Nomura::DRAFT::SharedData',
    required    => 1,
);

# The verbs supported by this plugin
has 'verbs'   => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    trigger     => \&_set_verbs,
);

# The transport layer
has 'transport' => (
    is          => 'rw',
    isa         => 'Nomura::DRAFT::Transport',
    required    => 1,
);

has 'log' => (
    is          => 'rw',
    lazy_build  => 1,
    builder     => '_build_log',
);

sub _build_log {
    my ($self) = @_;

    Log::Log4perl->get_logger( ref($self) );
}

# Create methods for each of the verbs defined by the controller constructor.
# Each of these methods delegates the actual call to the transport 'send' method
#
sub _set_verbs{
    my ($self, $new_verbs, $old_verbs) = @_;

    my $meta = $self->meta;
    $meta->make_mutable;

    if (defined $old_verbs) {
        print STDERR "OLD_VERBS: ".Dumper($old_verbs);
        die "We do not support the removal of old verbs";
    }
    for my $verb (@$new_verbs) {
        # Execute the verb through the transport layer
        $meta->add_method($verb => sub { my ($self) = @_; return $self->transport->send($self, $verb); } );
    }
    $meta->make_immutable;
}

1;

=head1 Nomura::DRAFT::Controller::Plugin

header

=cut


