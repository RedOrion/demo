package Nomura::EPS::NS::API::LDAP::NCD::Result::User;

use Moose;
use Carp;

extends 'Nomura::EPS::NS::API::LDAP::Result';

has 'login_shell'       => (is => 'rw', isa => 'Str');
has 'employee_number'   => (is => 'rw', isa => 'Str');
has 'given_name'        => (is => 'rw', isa => 'Str');
has 'surname'           => (is => 'rw', isa => 'Str');
has 'full_name'         => (is => 'rw', isa => 'Str');
has 'gid_number'        => (is => 'rw', isa => 'Int');
has 'home_directory'    => (is => 'rw', isa => 'Str');
has 'uid'               => (is => 'rw', isa => 'Str');
has 'uid_number'        => (is => 'rw', isa => 'Int');
has 'description'       => (is => 'rw', isa => 'Maybe[Str]');
has 'user_password'     => (is => 'rw', isa => 'Maybe[Str]');
has 'last_password_change'  => (is => 'rw', isa => 'Maybe[Str]');
has 'password_expiry_date'  => (is => 'rw', isa => 'Maybe[Str]');

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=head1 NAME

Nomura::EPS::NS::API::LDAP::NCD::Result::User - NCD Result User Class

=head1 DESCRIPTION

This class extends X<lib/Nomura/EPS/NS/API/LDAP/Result.pm> to provide an interface to
the user data on the NCD LDAP.

=head1 ATTRIBUTES

=over

=item * B<login_shell> the login shell of the user on the LDAP server.

=item * B<employee_number> the employee number

=item * B<given_name> the first name of the user

=item * B<surname> the surname name of the user

=item * B<full_name> the full name of the user

=item * B<gid_number> the GID Number of the user

=item * B<home_directory> the home directory of the user

=item * B<uid> the UID of the user

=item * B<uid_number> the numeric UID of the user

=item * B<description> a description to go with the user record

=back

=head1 METHODS

All methods are inherited from X<lib/Nomura/EPS/NS/API/LDAP/Result.pm>

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
