package Nomura::EPS::NS::API::Middleware::Factory;

# Module to create classes dynamically based on the database definitions
use Moose;
use Data::Dumper;

has 'schema' => (is => 'rw');

use namespace::autoclean;
$Data::Dumper::Indent = 1;

# Update the Object definitions
# This will be called each time the database definitions are changed in order
# to re-define the objects based on the database
# Any existing objects will retain their existing attributes, only new objects
# will be created with the changed attributes.
#
sub update_meta_objects {
    my ($self) = @_;

    my @objects = $self->schema->resultset('Object')->all_live_objects;

    for my $object (@objects) {
        my $obj_name = ucfirst $object->name;

        ### The ResultSet class
        # make the class mutable
        my $resultset_class = "Nomura::EPS::NS::API::Middleware::ResultSet::$obj_name";

        my $meta = Moose::Meta::Class->create($resultset_class);
        $meta->make_mutable;

        # Update the ResultSet class meta data
        $meta = Moose::Meta::Class->create(
            $resultset_class => (
                version         => $object->object_version_id,
                superclasses    => [$object->resultset_class],
            )
        );

        # Construct the 'attr' structure
        my ($key_attribute) = grep {$_->is_ldap_key == 1} $object->attributes;

        my $attr;
        $attr->{key} = $key_attribute->name;
        map {
            $attr->{tooltips}{$_->name} = $_->tooltip
            } $object->attributes;

        my @ldap_server_names = @{Nomura::EPS::NS::API::Middleware->ldap_server_names};
        for my $ldap_name (@ldap_server_names) {
            $attr->{read_from}{$ldap_name}  = [map {$_->name} grep {$_->read_from_ldap eq $ldap_name} $object->attributes];

            my @attribute_ids = map {$_->id} $object->attributes->search({
                is_ldap_key => 0,
            });

            my @write_to = $self->schema->resultset('WriteAttributeTo')->search({
                    attribute_id    => [@attribute_ids],
                    write_to_ldap   => $ldap_name,
                },{
                    prefetch    => 'attribute',
                }
            );
            $attr->{write_to}{$ldap_name} = [map {$_->attribute->name} @write_to];
        }

        $meta->add_attribute(attr => {
            is      => 'ro',
            isa     => 'HashRef',
            default => sub {$attr},
        });
        $meta->make_immutable;


        ### The Result class
        my $result_class = "Nomura::EPS::NS::API::Middleware::Result::$obj_name";

        $meta = Moose::Meta::Class->create($result_class);
        $meta->make_mutable;

        # Update the class meta data
        $meta = Moose::Meta::Class->create(
            $result_class => (
                version         => $object->object_version_id,
                superclasses    => [$object->result_class],
            )
        );

        # Remove all existing attributes before adding new one's
        my @attribs = $meta->get_attribute_list;
        for my $attrib (@attribs) {
            $meta->remove_attribute($attrib);
        }

        # Add all new attributes
        for my $attribute ($object->attributes) {
            my $name        = $attribute->name;
            my $is          = $attribute->readonly ? 'ro' : 'rw';
            my $isa         = $attribute->isa_type;
            if ($attribute->isa_array) {
                $isa        = "ArrayRef[$isa]";
            }
            if ($attribute->isa_maybe) {
                $isa        = "Maybe[$isa]";
            }
            $meta->add_attribute($name => (is => $is, isa => $isa, required => $attribute->required));
        }
        $meta->make_immutable;
    }
}

__PACKAGE__->meta->make_immutable;

1;



=head1 NAME

Nomura::EPS::NS::API::Middleware::Factory - Factory to make Middleware objects

=head1 SYNOPSIS

  my $factory = Nomura::EPS::NS::API::Middleware::Factory->new({
    schema => $schema,
  });

  # Update the Middleware from the database
  $factory->update_meta_objects;

=head1 DESCRIPTION

The Middleware factory will create/update all Middleware objects based on their
definition in the MySql database.

For example, if a B<Console> object is defined in the database, after the call
to the B<update_meta_objects> method, there will be two new classes defined,
B<Nomura::EPS::NS::API::Middleware::ResultSet::Console> and
B<Nomura::EPS::NS::API::Middleware::Result::Console> which inherit from their
base classes (also defined in the database, but usually B<Nomura::EPS::NS::API::Middleware::ResultSet>
and B<Nomura::EPS::NS::API::Middleware::Result> respectively).

If update_meta_objects is called a subsequent time then the existing definitions
for these classes are updated.

However, if there are any objects still in scope with the old definition
then these obects retain their original definition and only new objects
will be created with the new definition.

=head1 ATTRIBUTES

=head2 B<schema>

A schema L<DBIx::Class> object is the only attribute and this should be supplied
when the factory object is created.

=head1 METHODS

=head2 new

Create a new factory object (see synopsis>

=head2 update_meta_objects

Update all factory generated objects. See Synopsis and Description.

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

Copyright (c) 2011 Nomura Holdings, Inc. All rights reserved.

=cut
