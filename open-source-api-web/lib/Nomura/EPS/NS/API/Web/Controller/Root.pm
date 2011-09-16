package Nomura::EPS::NS::API::Web::Controller::Root;
use Moose;
use namespace::autoclean;
use FindBin;
use File::Find;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config->{namespace} = '';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#

# Automatically ensure that the Middleware objects are all created.
# It might be over-kill to do it for every request but unless there is a
# guaranteed place to put the code whenever the database is updated then
# it is probably best.
#
# An alternative would be to do a database query to see if the version
# number for the factory has changed and only then update the objects.
#
sub auto : Private {
    my ($self, $c) = @_;


    my $schema = $c->model('DB')->schema;
    my $factory = Nomura::EPS::NS::API::Middleware::Factory->new({schema => $schema});

    $factory->update_meta_objects;

    return 1;
}

# Display a page of POD documentation
#
sub pod_index : Path('pod') : Args(0) {
    my ($self, $c) = @_;

    do_pod($c, 'index.html');
}

sub pod : Path('pod') : Args(1) {
    my ($self, $c, $file) = @_;

    do_pod($c, $file);
}

sub do_pod {
    my ($c, $file) = @_;

    my $path    = "$FindBin::Bin/../";
    $file       = "$path/root/static/pod/".$file;

    $c->log->debug("pod path [$path] file [$file]");

    # Read the POD
    if (-e $file) {
        my $content = `cat $file`;

        # Adjust all local links within the document
        my $uri = $c->uri_for('/pod/');
        $content =~ s/\<\!--PODLINK--\>\<a href='/\<a href='$uri/g;

        $c->stash->{pod_document} = $content;
    }
    else {
        $c->stash->{pod_document} = "failure ";
    }
    $c->stash->{template} = 'pod.html';
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Nomura::EPS::NS::API::Web::Controller::Root - Root Controller for Nomura::EPS::NS::API::Web

=head1 DESCRIPTION

Root controller for LDAP API Interface

=head1 METHODS

=head2 index

The root page (/)

=head2 default

Standard 404 error page

=head2 pod

The on-line documentation page (/pod/<filename>)

=head2 end

Attempt to render a view, if needed.

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
