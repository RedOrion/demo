#!/usr/bin/env perl

# Test to see if we can change object models

use Moose;

use Test::More;
use FindBin::libs;
use Data::Dumper;
use Moose::Meta::Class;
use Moose::Meta::Attribute;

# Create the initial class definition
create_meta_1();

my $my_obj_1 = MyClass->new({foo => 'fred', bar => 2});
diag Dumper($my_obj_1);

# now see if we can re-define the class
# NOTE: creating a new Moose::Meta::Class object just returns the existing object (singleton)

create_meta_2();

my $my_obj_2 = MyClass->new({gee => 'barney', wiz => 4});
diag Dumper($my_obj_1);
diag Dumper($my_obj_2);


ok(1);


done_testing();

# create the initial class definition
sub create_meta_1 {
    my $meta1 = Moose::Meta::Class->create(
        "MyClass" => (
            version         => '0.01',
        )
    );
    $meta1->make_mutable;
    $meta1->add_attribute(foo => (is => 'rw', isa => 'Str'));
    $meta1->add_attribute(bar => (is => 'rw', isa => 'Int'));
    $meta1->make_immutable;

    diag "\n";
    diag "meta1 = [$meta1]\n";
}

# create a new class with different attributes
sub create_meta_2 {
    my $meta2 = Moose::Meta::Class->create(
        "MyClass" => (
            version         => '0.02',
        )
    );
    $meta2->make_mutable;
    $meta2->remove_attribute('foo');
    $meta2->remove_attribute('bar');

    $meta2->add_attribute(gee => (is => 'rw', isa => 'Str'));
    $meta2->add_attribute(wiz => (is => 'rw', isa => 'Int'));

    $meta2->make_immutable;

    diag "\n";
    diag "meta2 = [$meta2]\n";
}
