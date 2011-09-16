package Nomura::EPS::NS::API::Web::BaseController::REST;
use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller::REST' }

sub path_without_arg :Path('') :ActionClass('REST::ForBrowsers') {}

sub path_with_arg :Path('') :ActionClass('REST::ForBrowsers') :Args(1) {}

# path_with_arg_GET
#
*path_with_arg_GET_html = \&path_with_arg_GET;
sub path_with_arg_GET : Private {
    my ($self, $c, $object_id) = @_;

    my $object_name = ref $self;
    $object_name    =~ s/.*Controller::API::(.*)$/$1/;

    my $object_rs = $c->model('Middleware')->resultset($object_name);

    my $object = $object_rs->find($object_id);

    if ( $object ) {
        $self->status_ok(
            $c,
            entity  => $object->flatten($c->uri_for('/api/')),
        );
    }
    else {
        $self->status_not_found(
            $c,
            message  => "Cannot find that record",
        );
    }
}

# path_with_arg_PUT
#
# VERIFY: input arguments
# IF it is a new entry (the key does not exist)
#   Ensure that all 'required' fields are present
#   Ensure that all other fields satisfy the type constraint
# ELSE it is an update
#   Ensure that the nonce is present
#   Ensure that all specified fields satisfy the type constraint
#
# If fields are not present, report the error
# If fields do not satisfy the type constraint, report the error, give the actual constraints
#
# TRY to insert/update the record and report back any failures.
#
sub path_with_arg_PUT : Private {
    my ($self, $c, $key) = @_;

    my $object_name = ref $self;
    $object_name    =~ s/.*Controller::API::(.*)$/$1/;

    my $object_rs = $c->model('Middleware')->resultset($object_name);

    my $data = $c->request->data;

    my $errors = $object_rs->pre_validate_attributes($data);
    if ( ! $errors) {
        $errors = $object_rs->update_or_create($key, $data);
    }

    if ($errors) {
        $c->stash->{rest} = {
            error       => "One or more errors",
            code        => 2002,
            sub_errors  => $errors,
        };
        $c->response->status(400);
        return;
    }

    $self->status_ok(
        $c,
        entity  => {message => 'OK'},
    );
}


# path_with_arg_DELETE
#
sub path_with_arg_DELETE : Private {
    my ($self, $c, $object_id) = @_;

    my $object_name = ref $self;
    $object_name    =~ s/.*Controller::API::(.*)$/$1/;

    my $object_rs = $c->model('Middleware')->resultset($object_name);

    my $object = $object_rs->find($object_id);

    if ($object) {
        # try
        eval {
            $object->delete;
        };
        my $e;
        my $error_text;
        my $error_code;
        my $host        = 'unknown';

        if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
            $error_text     = $e->message;
            $host           = $e->host;
            $error_code     = $e->code;

        } elsif ($e = Exception::Class->caught()) {
            $error_text     = "Could not insert a new record, for an unknown reason ($e)";
            $error_code     = 2000;
        }
        if ($error_code) {
            $self->status_not_found(
                $c,
                message => "some internal error thingy",
            );
        }
    }
    else {
        $self->status_not_found(
            $c,
            message  => "Cannot find that record",
        );
    }

}

# path_without_arg_GET
#   Get a list of all objects that match the search terms
#   URI: /object/
#
*path_without_arg_GET_html = \&path_without_arg_GET;
sub path_without_arg_GET : Private {
    my ($self, $c) = @_;

    my $object_name = ref $self;
    $object_name    =~ s/.*Controller::API::(.*)$/$1/;
    my $object_rs   = $c->model('Middleware')->resultset($object_name);

    #### NOTE #### We should search on all terms, catch the exception and
    # report back if the caller tries to search on an illegal attribute.
    # At the moment we are just silently ignoring illegal attributes.
    #
    my $args;
    for my $term ($object_rs->get_search_terms) {
        my $req_param = $c->request->param($term);
        if ($req_param) {
            $args->{$term} = $req_param;
        }
    }
    my $objects = $object_rs->search(
        $args,
    );
    my @row_data;
    for my $object (@$objects) {
        push @row_data, $object->flatten($c->uri_for('/api/')),
    }

    $self->status_ok(
        $c,
        entity  => \@row_data,
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Nomura::EPS::NS::API::Web::REST - Base class for RESTful pages

=head1 DESCRIPTION

Controller methods for Objects.

=head1 METHODS

=head2 console

URI: (/console)

=head2 console GET

URI: (/console) with GET method

Search the list of consoles with the following search terms.

  hostname
  terminal_server
  terminal_port
  admin_port

Search terms are case insensitive and can include a wildcard '*' character

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
