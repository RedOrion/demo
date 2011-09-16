package Nomura::EPS::NS::API::Web::Controller::Rest;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Nomura::EPS::NS::API::Middleware;
use Nomura::EPS::NS::API::Constants qw(:API__ERROR :HTTP);

BEGIN {
    extends 'Catalyst::Controller::REST';
}
my $base_url = '/rest';

sub rest : Global : Args(0) {
    my ($self, $c) = @_;

    my $version = $c->model('DB::Configuration')->find('live_object_version')->value;
    my @object_names = map {$_->name} $c->model('DB::Object')->all_live_objects;
    my $urls;
    map { $urls->{$_} = $c->uri_for($base_url).'/'.$_ } @object_names;

    $c->stash->{rest} = {
        message             => "Welcome to the Nomura EPS NS API",
        version             => $version,
        supported_entities  => \@object_names,
        urls                => $urls,
    };
    $c->response->status($HTTP__OK);
    return;
}

sub chain_start : Chained('/') : PathPart('rest') : CaptureArgs(1) {
    my ($self, $c, $object) = @_;

    # Get all the Middleware object names

    # We should validate the object against the Middleware object names


    $object = ucfirst $object;
    $c->stash->{object} = $object;
}

sub path_without_arg :Chained('chain_start') :PathPart('') :Args(0) :ActionClass('REST::ForBrowsers') {}

sub path_with_arg :Chained('chain_start') :PathPart('') :Args(1) :ActionClass('REST::ForBrowsers') {}

# Find an object and put the response on the stash
#
sub find_object {
    my ($self, $c, $key) = @_;

    my ($data, $e, $object, $errors);

    my $object_rs = $c->model('Middleware')->resultset($c->stash->{object});

    # TRY
    eval {
        $object = $object_rs->find($key);
    };
    if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        $errors = $e->errors;
    }
    elsif ($e = Exception::Class->caught()) {
        $errors = [
            {
                message => "Unspecified error ($e)",
                code    => $API__ERROR__GENERAL_ERROR,
            },
        ];
    }

    if ($object) {
        $data = $object->flatten($c->uri_for($base_url.'/'));
    }
    else {
        # Shift the 'cannot find record' error onto the front of the errors


        $data = {
            errors => [
                {
                    message => 'Cannot find record',
                    code    => "$API__ERROR__CANNOT_FIND_RECORD",
                },
            ],
        };
    }

    $data->{meta_data}  = $object_rs->meta_data;
    $data->{urls}       = {
        home_url    => $c->uri_for($base_url).'/',
        base_url    => $c->uri_for($base_url).'/'.lc $c->stash->{object},
    };
    $c->stash->{rest} = $data;

}



# Put an object response on the stash
#
sub object_response {
    my ($self, $c, $object) = @_;

    my $data;

    if ($object) {
        $data = $object->flatten($c->uri_for($base_url.'/'));
    }
    else {
        $data = {
            errors => [
                {
                    message => 'Cannot find record',
                    code    => "$API__ERROR__CANNOT_FIND_RECORD",
                },
            ],
        };
    }

    my $object_rs = $c->model('Middleware')->resultset($c->stash->{object});

    $data->{meta_data}  = $object_rs->meta_data;
    $data->{urls}       = {
        home_url    => $c->uri_for($base_url).'/',
        base_url    => $c->uri_for($base_url).'/'.lc $c->stash->{object},
    };
    $c->stash->{rest} = $data;

    $c->response->status($HTTP__OK);
}


# path_with_arg_GET
#
*path_with_arg_GET_html = \&path_with_arg_GET;
sub path_with_arg_GET : Private {
    my ($self, $c, $object_id) = @_;

    my $object_rs = $c->model('Middleware')->resultset($c->stash->{object});
    my ($e, $object, $errors);

    # TRY
    eval {
        $object = $object_rs->find($object_id);
    };
    if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        $errors = $e->errors;
    }
    elsif ($e = Exception::Class->caught()) {
        $errors = [
            {
                message => 'Unspecified error',
                code    => $API__ERROR__GENERAL_ERROR,
            },
        ];
    }

    if ($errors) {
        $c->stash->{rest} = {
            errors => $errors,
        };
    }
    else {
        $self->object_response($c, $object);
    }
    $c->response->status($HTTP__OK);
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

    my $object_name = $c->stash->{object};

    my $object_rs = $c->model('Middleware')->resultset($object_name);

    my $data = $c->request->data;

    my ($e, $object, $errors);
    # TRY
    eval {
        $object_rs->pre_validate_attributes($data);
        $object = $object_rs->update_or_create($key, $data);
    };
    if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        $c->log->error("Caught errors; first error = ".$e->errors->[0]{message});
        $errors = $e->errors;
    }
    elsif ($e = Exception::Class->caught()) {
        $c->log->error("Caught an unspecified error - $e");
        $errors = [
            {
                message => 'Unspecified error',
                code    => $API__ERROR__GENERAL_ERROR,
            },
        ];
    }

    if ($errors) {
        $c->stash->{rest} = {
            errors => $errors,
        };
    }
    else {
        $self->object_response($c, $object);
    }

    $c->response->status($HTTP__OK);
}


# path_with_arg_DELETE
#
sub path_with_arg_DELETE : Private {
    my ($self, $c, $object_id) = @_;

    $c->log->info('path_with_arg_DELETE');

    my $object_name = $c->stash->{object};

    my $object_rs = $c->model('Middleware')->resultset($object_name);

    my $object = $object_rs->find($object_id);

    my $errors;
    if ($object) {
        $c->log->debug('deleting an existing object');
        # try
        eval {
            $object->delete;
        };
        my $e;

        if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
            $errors = $e->errors;
        } elsif ($e = Exception::Class->caught()) {
            $errors = [
                {
                    message => "Could not delete the record, for an unknown reason ($e)",
                    code    => $API__ERROR__CANNOT_DELETE_RECORD,
                },
            ];
        }
    }
    else {
        $c->log->debug('could not find that record to delete');
        $errors = [
            {
                message => "Could not find that record.",
                code    => $API__ERROR__CANNOT_FIND_RECORD,
            },
        ];
    }

    if ($errors) {
        $c->stash->{rest} = {
            errors => $errors,
        };
    }
    else {
        $c->stash->{rest} = {
            meta_data   => $object_rs->meta_data,
            data        => $object->flatten($c->uri_for($base_url.'/')),
            urls        => {
                home_url    => $c->uri_for($base_url).'/',
                base_url    => $c->uri_for($base_url).'/'.lc $object_name,
            },
        };
    }
    $c->response->status($HTTP__OK);
}

# path_without_arg_GET
#   Get a list of all objects that match the search terms
#   URI: /object/
#
*path_without_arg_GET_html = \&path_without_arg_GET;
sub path_without_arg_GET : Private {
    my ($self, $c) = @_;

    my $object_name = $c->stash->{object};
    $c->log->debug("Object name is [$object_name]");

    my $object_rs   = $c->model('Middleware')->resultset($object_name);
    $c->log->debug("object_rs=[$object_rs]");

    my @search_terms = $object_rs->get_search_terms;
    $c->log->debug("search terms are @search_terms");

    my $errors;
    my $args;

    TERM:
    for my $term (keys %{$c->request->params}) {
        # If the term is not in the list of search terms flag an error
        if (grep {$term eq $_} @search_terms) {
            $c->log->debug("Search term [$term] is valid");
            my $req_param = $c->request->param($term);
            if ($req_param) {
                $args->{$term} = $req_param;
            }
        }
        else {
            $c->log->debug("Search term [$term] is *not* valid");
            push @$errors, {
                message     => 'Cannot search on that field',
                code        => $API__ERROR__ILLEGAL_SEARCH_TERM,
                attribute   => $term,
            };
        }
    }

    my ($e, $objects);
    if (not $errors) {
        # TRY
        eval {
            $objects = $object_rs->search(
                $args,
            );
        };
        # CATCH
        if ($e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
            $errors = $e->errors;
        }
        elsif ($e = Exception::Class->caught()) {
            $errors = [
                {
                    message => "Unspecified error $e",
                    code    => $API__ERROR__GENERAL_ERROR,
                },
            ];
        }
    }

    if ($errors) {
        $c->stash->{rest} = {
            errors  => $errors,
        };
    }
    else {
        my @row_data;
        for my $object (@$objects) {
            push @row_data, $object->flatten($c->uri_for($base_url.'/')),
        }

        $c->stash->{rest} = {
            meta_data   => $object_rs->meta_data,
            data        => \@row_data,
            urls        => {
                home_url    => $c->uri_for($base_url).'/',
                base_url    => $c->uri_for($base_url).'/'.lc $object_name,
            },
        };
    }
    $c->response->status($HTTP__OK);
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=pod

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

Copyright (c) 2011 Nomura Holdings, Inc. All rights reserved.

