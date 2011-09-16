package Nomura::EPS::NS::API::Web::View::TT;

use Moose;
use namespace::autoclean;

=head1 NAME

Nomura::EPS::NS::API::Web::View::JSON - View returning Template Toolkit

=head1 DESCRIPTION

A thin wrapper around L<Catalyst::View::TT> that provides a View in Template Toolkit

=cut

BEGIN {extends 'Catalyst::View::TT'};

=head1 METHODS

None.

=cut

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;