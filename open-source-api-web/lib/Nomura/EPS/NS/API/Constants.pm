package Nomura::EPS::NS::API::Constants;

use strict;
use warnings;

use Exporter qw(import);
use Readonly;

=head1 NAME

Nomura::EPS::NS::API::Constants - System wide constants

=head1 DESCRIPTION

Provides a single point at which constants can be defined

=cut

Readonly::Scalar our $API__ERROR__GENERAL_ERROR             => 1000;
Readonly::Scalar our $API__ERROR__CANNOT_FIND_RECORD        => 1001;
Readonly::Scalar our $API__ERROR__CANNOT_CREATE_RECORD      => 1002;
Readonly::Scalar our $API__ERROR__CANNOT_DELETE_RECORD      => 1003;
Readonly::Scalar our $API__ERROR__MISSING_MANDATORY_FIELD   => 1004;
Readonly::Scalar our $API__ERROR__MISSING_NONCE             => 1005;
Readonly::Scalar our $API__ERROR__CHANGED_NONCE             => 1006;
Readonly::Scalar our $API__ERROR__TYPE_CONSTRAINT           => 1007;
Readonly::Scalar our $API__ERROR__CANNOT_MODIFY_KEY         => 1008;
Readonly::Scalar our $API__ERROR__CANNOT_UPDATE_FIELD       => 1009;
Readonly::Scalar our $API__ERROR__NOT_FOUND_ON_NCD          => 1010;
Readonly::Scalar our $API__ERROR__NO_LDAP_CONNECTION        => 1011;
Readonly::Scalar our $API__ERROR__CANNOT_CREATE_LDAP_RECORD => 1012;
Readonly::Scalar our $API__ERROR__CANNOT_UPDATE_LDAP_FIELD  => 1013;
Readonly::Scalar our $API__ERROR__CANNOT_DELETE_LDAP_RECORD => 1014;
Readonly::Scalar our $API__ERROR__CANNOT_ROLLBACK_ERROR     => 1015;
Readonly::Scalar our $API__ERROR__INVALID_ATTRIBUTE         => 1016;
Readonly::Scalar our $API__ERROR__ILLEGAL_SEARCH_TERM       => 1017;
Readonly::Scalar our $API__ERROR__LDAP_INSERT_ERROR         => 1018;
Readonly::Scalar our $API__ERROR__CANNOT_FIND_OBJECT        => 1019;



Readonly::Scalar our $API__FOO__BAR                         => 'thingy';

# Some of the more common HTTP response codes
Readonly::Scalar our $HTTP__OK                              => 200;
Readonly::Scalar our $HTTP__BAD_REQUEST                     => 400;
Readonly::Scalar our $HTTP__FORBIDDEN                       => 403;
Readonly::Scalar our $HTTP__NOT_FOUND                       => 404;


### The following section (could/should) be created programatically with the right tool. TBD
### --- start --- (when the tool is written) do not manually change anything between this line and the ### --- end --- tag

Readonly::Scalar our $API__ERROR => {
    GENERAL_ERROR               => $API__ERROR__GENERAL_ERROR,
    CANNOT_FIND_RECORD          => $API__ERROR__CANNOT_FIND_RECORD,
    CANNOT_CREATE_RECORD        => $API__ERROR__CANNOT_CREATE_RECORD,
    CANNOT_DELETE_RECORD        => $API__ERROR__CANNOT_DELETE_RECORD,
    MISSING_MANDATORY_FIELD     => $API__ERROR__MISSING_MANDATORY_FIELD,
    MISSING_NONCE               => $API__ERROR__MISSING_NONCE,
    CHANGED_NONCE               => $API__ERROR__CHANGED_NONCE,
    TYPE_CONSTRAINT             => $API__ERROR__TYPE_CONSTRAINT,
    CANNOT_MODIFY_KEY           => $API__ERROR__CANNOT_MODIFY_KEY,
    CANNOT_UPDATE_FIELD         => $API__ERROR__CANNOT_UPDATE_FIELD,
    CHANGED_NONCE               => $API__ERROR__CHANGED_NONCE,
    NOT_FOUND_ON_NCD            => $API__ERROR__NOT_FOUND_ON_NCD,
    NO_LDAP_CONNECTION          => $API__ERROR__NO_LDAP_CONNECTION,
    CANNOT_CREATE_LDAP_RECORD   => $API__ERROR__CANNOT_CREATE_LDAP_RECORD,
    CANNOT_UPDATE_LDAP_FIELD    => $API__ERROR__CANNOT_UPDATE_LDAP_FIELD,
    CANNOT_DELETE_LDAP_RECORD   => $API__ERROR__CANNOT_DELETE_LDAP_RECORD,
    CANNOT_ROLLBACK_ERROR       => $API__ERROR__CANNOT_ROLLBACK_ERROR,
    INVALID_ATTRIBUTE           => $API__ERROR__INVALID_ATTRIBUTE,
    ILLEGAL_SEARCH_TERM         => $API__ERROR__ILLEGAL_SEARCH_TERM,
    LDAP_INSERT_ERROR           => $API__ERROR__LDAP_INSERT_ERROR,
    CANNOT_FIND_OBJECT          => $API__ERROR__CANNOT_FIND_OBJECT,

};

Readonly::Scalar our $API__FOO => {
    BAR     => 'thingy',
};

Readonly::Scalar our $HTTP => {
    OK          => $HTTP__OK,
    BAD_REQUEST => $HTTP__BAD_REQUEST,
    FORBIDDEN   => $HTTP__FORBIDDEN,
    NOT_FOUND   => $HTTP__NOT_FOUND,
};

Readonly::Scalar our $API => {
    ERROR   => $API__ERROR,
    FOO     => $API__FOO,
};

our @EXPORT_OK = qw(
    $API
    $API__ERROR
    $API__FOO
    $API__ERROR__GENERAL_ERROR
    $API__ERROR__CANNOT_FIND_RECORD
    $API__ERROR__CANNOT_CREATE_RECORD
    $API__ERROR__CANNOT_DELETE_RECORD
    $API__ERROR__MISSING_MANDATORY_FIELD
    $API__ERROR__MISSING_NONCE
    $API__ERROR__CHANGED_NONCE
    $API__ERROR__TYPE_CONSTRAINT
    $API__ERROR__CANNOT_MODIFY_KEY
    $API__ERROR__CANNOT_UPDATE_FIELD
    $API__ERROR__CHANGED_NONCE
    $API__ERROR__NOT_FOUND_ON_NCD
    $API__ERROR__NO_LDAP_CONNECTION
    $API__ERROR__CANNOT_CREATE_LDAP_RECORD
    $API__ERROR__CANNOT_UPDATE_LDAP_FIELD
    $API__ERROR__CANNOT_DELETE_LDAP_RECORD
    $API__ERROR__CANNOT_ROLLBACK_ERROR
    $API__ERROR__INVALID_ATTRIBUTE
    $API__ERROR__ILLEGAL_SEARCH_TERM
    $API__ERROR__CANNOT_FIND_OBJECT
    $API__ERROR__LDAP_INSERT_ERROR
    $API__FOO__BAR
    $HTTP
    $HTTP__OK
    $HTTP__BAD_REQUEST
    $HTTP__FORBIDDEN
    $HTTP__NOT_FOUND
);

our %EXPORT_TAGS = (
    API => [qw(
        $API
        $API__ERROR
        $API__FOO
        $API__ERROR__GENERAL_ERROR
        $API__ERROR__CANNOT_FIND_RECORD
        $API__ERROR__CANNOT_CREATE_RECORD
        $API__ERROR__CANNOT_DELETE_RECORD
        $API__ERROR__MISSING_MANDATORY_FIELD
        $API__ERROR__MISSING_NONCE
        $API__ERROR__CHANGED_NONCE
        $API__ERROR__TYPE_CONSTRAINT
        $API__ERROR__CANNOT_MODIFY_KEY
        $API__ERROR__CANNOT_UPDATE_FIELD
        $API__ERROR__CHANGED_NONCE
        $API__ERROR__NOT_FOUND_ON_NCD
        $API__ERROR__NO_LDAP_CONNECTION
        $API__ERROR__CANNOT_CREATE_LDAP_RECORD
        $API__ERROR__CANNOT_UPDATE_LDAP_FIELD
        $API__ERROR__CANNOT_DELETE_LDAP_RECORD
        $API__ERROR__CANNOT_ROLLBACK_ERROR
        $API__ERROR__INVALID_ATTRIBUTE
        $API__ERROR__ILLEGAL_SEARCH_TERM
        $API__ERROR__CANNOT_FIND_OBJECT
        $API__ERROR__LDAP_INSERT_ERROR
        $API__FOO__BAR
    )],
    API__ERROR => [qw(
        $API__ERROR
        $API__ERROR__GENERAL_ERROR
        $API__ERROR__CANNOT_FIND_RECORD
        $API__ERROR__CANNOT_CREATE_RECORD
        $API__ERROR__CANNOT_DELETE_RECORD
        $API__ERROR__MISSING_MANDATORY_FIELD
        $API__ERROR__MISSING_NONCE
        $API__ERROR__CHANGED_NONCE
        $API__ERROR__TYPE_CONSTRAINT
        $API__ERROR__CANNOT_MODIFY_KEY
        $API__ERROR__CANNOT_UPDATE_FIELD
        $API__ERROR__CHANGED_NONCE
        $API__ERROR__NOT_FOUND_ON_NCD
        $API__ERROR__NO_LDAP_CONNECTION
        $API__ERROR__CANNOT_CREATE_LDAP_RECORD
        $API__ERROR__CANNOT_UPDATE_LDAP_FIELD
        $API__ERROR__CANNOT_DELETE_LDAP_RECORD
        $API__ERROR__CANNOT_ROLLBACK_ERROR
        $API__ERROR__INVALID_ATTRIBUTE
        $API__ERROR__ILLEGAL_SEARCH_TERM
        $API__ERROR__CANNOT_FIND_OBJECT
        $API__ERROR__LDAP_INSERT_ERROR
    )],
    API__FOO => [qw(
        $API__FOO
        $API__FOO__BAR
    )],
    HTTP    => [qw(
        $HTTP__OK
        $HTTP__BAD_REQUEST
        $HTTP__FORBIDDEN
        $HTTP__NOT_FOUND
    )],
);

### --- end --- do not manually change anything between this line and the ### --- start --- tag

=head1 METHODS

None.

This module holds system wide constants which should be used in preference to using 'magic' numbers
in your source code.

The module also conforms to the 'Perl best Practices' book in that it defines
the constants using the L<Readonly> module.

=head2 standards

When defining constants, ensure they have a unique name prefix, for example when
defining constants for the Nomura::ITUK::Foo::Bar module, their names could start $FOO_BAR__
followed by the name of the constants. e.g. $FOO_BAR__CONST_1, $FOO_BAR__CONST_2. Note the double
underscore after the prefix. This is important (see below).

If you have several types of constants for the same module then you can provide a second (and third)
level name using additional sets of double-underscores. e.g. $FOO_BAR__STATUS__GOOD, $FOO_BAR__STATUS__BAD,
$FOO_BAR__STATUS__UGLY and then $FOO_BAR__CLASS__RED, $FOO_BAR__CLASS__AMBER, $FOO_BAR__CLASS__GREEN

=head2 exported symbols

There is a script (yet to be written) that will parse this file and automatically produce all the EXPORT_OK and EXPORT_TAGS
entries (ensure that you do not modify any lines between the B<--- start ---> and B<--- end ---> comment lines.

An EXPORT_OK entry will be created for all constants, e.g. $FOO_BAR__STATUS__GOOD, $FOO_BAR__STATUS__BAD etc.

An EXPORT_TAG will be created with the label prefix (upto the first double-underscore) which will contain
references to all constants in that set, e.g. 'FOO_BAR'

To includes constants from the FOO_BAR set, do the following in your source code.

    use Nomura::EPS::NS::API::Constants qw(:FOO_BAR );

This will import $FOO_BAR__STATUS__GOOD, $FOO_BAR__STATUS__BAD etc. into your name space.

A useful hash of the variables is also created and exported. For example

    %FOO_BAR => (
        STATUS  => {
            GOOD    => $FOO_BAR__STATUS__GOOD,
            BAD     => $FOO_BAR__STATUS__BAD,
            UGLY    => $FOO_BAR__STATUS__UGLY,
        },
        CLASS   => {
            RED     => $FOO_BAR__STATUS__RED,
            AMBER   => $FOO_BAR__STATUS__AMBER,
            GREEN   => $FOO_BAR__STATUS__GREEN,
        }
    );

This is especially useful it Templates where you want to access some or all of the constants from a set.

In your controller

    use Nomura::EPS::NS::Constants qw(:FOO_BAR );

    $c->stash->{FOO_BAR} = \%FOO_BAR;

In the template

    <div>The UGLY constant has the value [% FOO_BAR.STATUS.UGLY %]</div>

=cut

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
