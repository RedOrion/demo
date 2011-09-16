package Nomura::EPS::NS::API::Web::Model::Middleware;

use strict;
use warnings;

use base 'Catalyst::Model::Factory::PerRequest';

1;

=pod

=head1 NAME

Nomura::EPS::NS::API::Web::Model::Middleware - Catalyst Model to Middleware

=head1 SYNOPSIS

  my ($console) = $c->model('Middleware')->resultset->search({
    hostname => 'test_host_123',
  });

=head1 DESCRIPTION

This module is a thin wrapper around the API Middleware layer X<lib/Nomura/EPS/NS/API/Middleware.pm>
so that Catalyst can access it while allowing the middleware layer to be independent of
Catalyst (for example, so that it can be used by command line tools).

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2011 Nomura Holdings, Inc. All rights reserved.

=cut
