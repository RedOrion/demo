#!/usr/bin/env perl

use lib '/local/0/sw/catalyst/perl5/lib/perl5/';
use lib '/local/0/sw/catalyst/perl5/lib/perl5/5.8.8/';
use lib '/local/0/sw/catalyst/perl5/lib/perl5/site_perl/5.8.8/';
use lib '/local/0/sw/catalyst/perl5/lib/perl5/x86_64-linux-thread-multi/';
use lib '/local/0/sw/catalyst/perl5/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/';

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Nomura::EPS::NS::API::Web', 'CGI');

1;

=head1 NAME

nomura_eps_ns_api_web_cgi.pl - Catalyst CGI

=head1 SYNOPSIS

See L<Catalyst::Manual>

=head1 DESCRIPTION

Run a Catalyst application as a cgi script.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

