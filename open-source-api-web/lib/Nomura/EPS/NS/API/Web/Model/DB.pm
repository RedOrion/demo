package Nomura::EPS::NS::API::Web::Model::DB;

use strict;

use base qw(Catalyst::Model::DBIC::Schema);

__PACKAGE__->config(
    schema_class    => 'Nomura::EPS::NS::Middleware::DB',
    connect_info    => [
        Nomura::EPS::NS::API::Web->config->{DBD}{dsn},
        Nomura::EPS::NS::API::Web->config->{DBD}{username},
        Nomura::EPS::NS::API::Web->config->{DBD}{password},
        Nomura::EPS::NS::API::Web->config->{DBD}{dbi_attr},
    ],
);

1;



=head1 NAME

Nomura::EPS::NS::API::Web::Model::DB - Catalyst Model to Database

=head1 SYNOPSIS

  my ($attribute) = $c->model('DB::Attribute')->search({
    name => 'hostname',
  });

=head1 DESCRIPTION

This module is a thin wrapper around the Middleware database, X<lib/Nomura/EPS/NS/Middleware/DB.pm>
so that Catalyst can access it while allowing the database access code to be independent of
Catalyst (for example, so that it can be used by command line tools).

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2011 Nomura Holdings, Inc. All rights reserved.

=cut
