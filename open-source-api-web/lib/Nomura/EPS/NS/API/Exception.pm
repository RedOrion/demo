package Nomura::EPS::NS::API::Exception;

use base 'Exporter';

use Exception::Class (
    Nomura::EPS::NS::API::Exception => {
        fields      => [qw(errors)],
        description => 'EPS Engineering API Exception class',
        alias       => 'throw_api_error',
    },
);

@Nomura::EPS::NS::API::Exception::EXPORT_OK = (qw(throw_api_error));
1;

=pod

=head1 NAME

Nomura::EPS::NS::API::Exception - Exception class

=head1 SYNOPSIS

    use Exception::Class;

    # try
    eval {
        $group->update({
            gid_number      => 1234465555,
            member_uids     => [qw(alpha beta gamma)],
            description     => ['description one'],
        });
    };

    # catch
    if (my $e = Exception::Class->caught('Nomura::EPS::NS::API::Exception')) {
        print "CAUGHT error [$e]\n";
        print "Error code ".$e->code."\n";
        print "Failed to update attribute ".$e->attribute."\n";
        print "LDAP attribute name ".$e->ldap_attribute."\n";
        print "on host ".$e->host."\n";

        # attempt a rollback of the error
        $group->rollback;

        exit;
    }

    # this script would produce something like the following on an exception
    CAUGHT error [Cannot update the record]
    Error code 1002
    Failed to update attribute member_uids
    LDAP attribute name memberUID
    on host tl0067.lehman.com

=head1 DESCRIPTION

This is the general purpose exception class for the Portal API.

Most of the API methods throw an exception rather than returning a status value.
This has the advantage that more information can be returned about the error than
a simple status value can provide. Also the error can be handled at the appropriate
call level rather than trying to propagate the error back through several calls.

Read B<OO Exceptions> from B<Perl Best Practices> for more details.

=head2 METHODS

See L<Exception::Class>, which this class inherits from, for more details.

=head1 AUTHOR

Ian Docherty ian.docherty@nomura.com

=head1 LICENSE

Copyright (c) 2001-2011 Nomura Holdings, Inc. All rights reserved.

=cut
