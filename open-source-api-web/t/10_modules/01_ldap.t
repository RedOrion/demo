#!/usr/bin/env perl

# Basic tests of the LDAP interface

use strict;
use warnings;
use Test::More;
use Test::MockModule;
use FindBin::libs;
use Data::Dumper;
use Module::Find;
use Exception::Class;

BEGIN {
    useall Nomura::EPS::NS::API::LDAP;
}

my $ncd = Nomura::EPS::NS::API::LDAP::NCD->new({
    host              => 'tl0067.lehman.com',
    base              => 'ou=consoles,dc=nomura,dc=com',
    dn                => 'cn=Directory Manager',
    password          => 'K0rolyov',
    start_tls         => 0,
});

isa_ok($ncd, 'Nomura::EPS::NS::API::LDAP::NCD');

# Ensure all test data has been removed ready for us to add it

my $rs = $ncd->resultset('Group');

my $groups = $rs->search({
    group_name      => 'testing*',
});

for my $group (@$groups) {
    $group->delete;
}

# create a new instance and put it on the LDAP server
my $group = $rs->create({
    group_name      => 'testing325',
    gid_number      => 1234465555,
    member_uids     => [qw(alpha beta gamma)],
    description     => ['desc one'],
    user_password   => [qw(password1 password2 password3)],
});

isa_ok($group, 'Nomura::EPS::NS::API::LDAP::NCD::Result::Group');

# check that we can re-read this object from the server
my $ro_group = $rs->find('testing325');
isa_ok($ro_group, 'Nomura::EPS::NS::API::LDAP::NCD::Result::Group');

is($ro_group->group_name,          'testing325',   'group_name is correct');
is($ro_group->gid_number,          '1234465555',   'gid_number is correct');
is_deeply($ro_group->member_uids, [qw(alpha beta gamma)], 'all member_uids are correct');
is_deeply($ro_group->description, ['desc one'], 'description is correct');

# We can't read passwords back, they are encrypted!
#is_deeply($ro_group->user_password, ['password1','password2','password3'], 'all user_passwords are correct');

# check that we can update this object locally
$group->gid_number(987654321);
is($group->gid_number, 987654321, 'gid_number local update');

$group->member_uids([qw(one two three)]);
is_deeply($group->member_uids, [qw(one two three)], 'all member_uids are updated correctly');
$group->user_password([qw(secret1 secret2)]);
is_deeply($group->user_password, [qw(secret1 secret2)], 'all user_passwords are updated correctly');

# now update the server with these changes
$group->update;

# check that we can re-read these changes from the server
# At this point we should have
#   member_uids [one two three]
#   user_password [{crypt}xxxx {crypt}xxxx]
#   gid_number 987654321
#
$group = $rs->find('testing325');
$group->member_uids([qw(one two three)]);
is_deeply($group->member_uids, [qw(one two three)], 'all member_uids are updated correctly');

# remember the 'crypt'ed passwords so we can check the rollback
my $crypted_passwords = [@{$group->user_password}];

$group->user_password([qw(secret1 secret2)]);
is_deeply($group->user_password, [qw(secret1 secret2)], 'all user_passwords are updated correctly');

# REMOTE rollback tests
# put changes on the server and see if we can rollback
diag "REMOTE rollback tests";
$group->gid_number(11111111);
is($group->gid_number, 11111111, 'gid_number local update');
$group->member_uids([qw(john bert barny)]);
is_deeply($group->member_uids, [qw(john bert barny)], 'all member_uids local update');
$group->user_password([qw(pass_1 pass_2)]);
is_deeply($group->user_password, [qw(pass_1 pass_2)], 'all user_passwords local update');

# Do a successful update.
$group->update;

# Rollback after success

diag "ROLLBACK after a success update. Should have no effect";
$group->rollback;
is($group->gid_number, 11111111, 'gid_number remote rollback after successful update');
is_deeply($group->member_uids, [qw(john bert barny)], 'all member_uids remote rollback after successful update');

my $attr_to_fail = 'gidNumber';

# Test using Test::MockModule to simulate a failed write to an attribute
my $mock_obj = new Test::MockModule("Net::LDAP");
$mock_obj->mock(
    modify  => sub {
        my ($self, $dn, %options) = @_;
        my ($attr) = $options{changes}->[1][0];
        # Only mock the attribute that is to fail
        if ($attr eq $attr_to_fail) {
            return { resultCode => 1};
        }
        else {
            # All other attributes make the original call
            my $original = $mock_obj->original('modify');
            return &$original($self,$dn, %options);
        }
    }
);

$group->description(['new description']);
$group->gid_number(555);

my $result;
eval {
    $result = $group->update;
};

my $e = Exception::Class->caught();

isa_ok($e, 'Nomura::EPS::NS::API::Exception');

$mock_obj->unmock('modify');

is($result, undef, 'update should have failed');
# Check that all except the 'description' have been rolled back.
is_deeply($group->description, ['new description'], 'description after error');
is($group->gid_number, 11111111, 'gid_number after error');
is_deeply($group->member_uids, [qw(john bert barny)], 'member_uids after error');

$group->rollback;

diag "ROLLBACK after a failure update. Should restore the values";
is_deeply($group->description, ['desc one'], 'description after rollback');
is($group->gid_number, 11111111, 'gid_number after rollback');
is_deeply($group->member_uids, [qw(john bert barny)], 'member_uids after rollback');

done_testing();
