package mop::bootstrap;

use strict;
use warnings;

use Clone ();
use Package::Anon;
use PadWalker ();
use Scalar::Util 'weaken';
use Scope::Guard 'guard';

use mop::internal::class;
use mop::internal::instance;
use mop::internal::attribute;
use mop::internal::method;


{
    my %STASHES;

    sub get_stash_for {
        my $class = shift;
        my $uuid  = mop::internal::instance::get_uuid( $class );
        return $STASHES{ $uuid } if exists $STASHES{ $uuid };
        return;
    }

    sub new_stash_for {
        my $class = shift;
        my $uuid = mop::internal::instance::get_uuid( $class );
        my $name = mop::internal::instance::get_slot_at( $class, '$name' );
        $STASHES{ $uuid } = Package::Anon->new( $name );
    }

    sub generate_stash_for {
        my $class = shift;
        my $uuid  = mop::internal::instance::get_uuid( $class );
        $STASHES{ $uuid } = $class->GENSTASH;
    }
}

sub init {

    ## --------------------------------
    ## Create our classes
    ## --------------------------------

    $::Class = mop::internal::class::create(
        class      => \$::Class,
        name       => 'Class',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        attributes => {},
        methods    => {
            'add_method' => mop::internal::method::create(
                name => 'add_method',
                body => sub {
                    my $method = shift;

                    get_stash_for( $::Method )->bless( $method );

                    mop::internal::instance::get_slot_at( $::SELF, '$methods' )->{
                        mop::internal::instance::get_slot_at( $method, '$name' )
                    } = $method;

                    if ( my $stash = get_stash_for( $::SELF ) ) {
                        # NOTE:
                        # we won't always have a stash
                        # because it is created at FINALIZE
                        # and not when the class itself is
                        # created.
                        # - SL
                        $stash->add_method(
                            mop::internal::instance::get_slot_at( $method, '$name' ),
                            sub { mop::internal::method::execute( $method, @_ ) }
                        );
                    }
                }
            ),
        }
    );

    $::Object = mop::internal::class::create(
        class      => \$::Class,
        name       => 'Object',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        attributes => {},
        methods    => {},
    );

    $::Method = mop::internal::class::create(
        class      => \$::Class,
        name       => 'Method',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        superclass => $::Object,
        methods    => {},
        attributes => {},
    );

    $::Attribute = mop::internal::class::create(
        class      => \$::Class,
        name       => 'Attribute',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        superclass => $::Object,
        methods    => {},
        attributes => {},
    );

    ## --------------------------------
    ## START BOOTSTRAP
    ## --------------------------------

    mop::internal::instance::set_slot_at( $::Class, '$superclass', \$::Object );

    new_stash_for( $::Object    );
    new_stash_for( $::Class     );
    new_stash_for( $::Method    );
    new_stash_for( $::Attribute );

    get_stash_for( $::Class )->bless( $::Object    );
    get_stash_for( $::Class )->bless( $::Class,    );
    get_stash_for( $::Class )->bless( $::Method,   );
    get_stash_for( $::Class )->bless( $::Attribute );

    get_stash_for( $::Method )->bless( mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'add_method'} );

    get_stash_for( $::Class )->add_method( add_method => sub { mop::internal::method::execute( mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'add_method'}, @_ ) } );

    ## --------------------------------
    ## $::Class
    ## --------------------------------

    ## instance access

    $::Class->add_method( mop::internal::method::create( name => 'get_slot', body => sub { mop::internal::instance::get_slot( $_[0] ) } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_slot_at', body => sub { ${ $::SELF->get_slot( $_[0] )->{ $_[1] } || \undef } } ) );
    $::Class->add_method( mop::internal::method::create( name => 'set_slot_at', body => sub { $::SELF->get_slot( $_[0] )->{ $_[1] } = $_[2] } ) );

    ## accessors

    $::Class->add_method( mop::internal::method::create( name => 'get_name',        body => sub { $::CLASS->get_slot_at( $::SELF, '$name' )       } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_version',     body => sub { $::CLASS->get_slot_at( $::SELF, '$version' )    } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_authority',   body => sub { $::CLASS->get_slot_at( $::SELF, '$authority' )  } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_superclass',  body => sub { $::CLASS->get_slot_at( $::SELF, '$superclass' ) } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_methods',     body => sub { $::CLASS->get_slot_at( $::SELF, '$methods' )    } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_attributes',  body => sub { $::CLASS->get_slot_at( $::SELF, '$attributes' ) } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_destructor',  body => sub { $::CLASS->get_slot_at( $::SELF, '$destructor' ) } ) );
    $::Class->add_method( mop::internal::method::create( name => 'get_constructor', body => sub { $::CLASS->get_slot_at( $::SELF, '$constructor' ) } ) );
    $::Class->add_method( mop::internal::method::create( name => 'attribute_class', body => sub { $::Attribute } ) );
    $::Class->add_method( mop::internal::method::create( name => 'method_class',    body => sub { $::Method } ) );

    $::Class->add_method( mop::internal::method::create( name => 'get_mro', body => sub {
        my $super = $::CLASS->get_slot_at( $::SELF, '$superclass' );
        return [
            $::SELF,
            $super ? @{ $super->get_mro } : (),
        ];
    }));
    $::Class->add_method( mop::internal::method::create( name => 'find_method', body => sub {
        $::CLASS->get_slot_at( $::SELF, '$methods' )->{ $_[0] };
    }));

    ## mutators

    $::Class->add_method( mop::internal::method::create( name => 'set_constructor', body => sub {
        my $constructor = shift;
        $::CLASS->set_slot_at( $::SELF, '$constructor', \$constructor );
    }));

    $::Class->add_method( mop::internal::method::create( name => 'set_destructor', body => sub {
        my $destructor = shift;
        $::CLASS->set_slot_at( $::SELF, '$destructor', \$destructor );
    }));

    $::Class->add_method( mop::internal::method::create( name => 'set_superclass', body => sub {
        my $superclass = shift;
        $::CLASS->set_slot_at( $::SELF, '$superclass', \$superclass );
    }));
    $::Class->add_method( mop::internal::method::create( name => 'add_attribute', body => sub {
        my $attr = shift;
        $::SELF->get_attributes->{ mop::internal::instance::get_class($attr)->get_slot_at( $attr, '$name' ) } = $attr;
    }));

    ## predicate methods ...

    $::Class->add_method( mop::internal::method::create( name => 'is_subclass_of', body => sub {
        my $superclass = shift;
        my @mro = @{ $::SELF->get_mro };
        shift @mro;
        return scalar grep { $superclass->equals( $_ ) } @mro;
    }));
    $::Class->add_method( mop::internal::method::create( name => 'equals', body => sub {
        my $other = shift;
        return mop::internal::instance::get_uuid($::SELF) eq mop::internal::instance::get_uuid($other);
    }));

    $::Class->add_method( mop::internal::method::create( name => 'get_compatible_class', body => sub {
        my $super = shift;

        return unless $super;

        if ( $::SELF->is_subclass_of( $super ) ) {
            return $::SELF;
        }
        elsif ( $super->is_subclass_of( $::SELF ) ) {
            return $super;
        }
        elsif ( $::SELF->equals( $super ) ) {
            return $super;
        }
        else {
            return;
        }
    }));

    ## class protocol

    $::Class->add_method( mop::internal::method::create( name => 'construct_instance', body => sub {
        mop::internal::instance::create( \$::SELF, $_[0] )
    }));
    $::Class->add_method( mop::internal::method::create( name => 'CREATE', body => sub {
        my $args = shift;
        my $data = {};

        foreach my $class ( @{ $::SELF->get_mro } ) {
            my $attrs = mop::internal::instance::get_class($class)->get_slot_at( $class, '$attributes' );
            foreach my $attr_name ( keys %$attrs ) {
                unless ( exists $data->{ $attr_name } ) {
                    my $param_name = $attr_name;
                    $param_name =~ s/^\$//;

                    if ( exists $args->{ $param_name } ) {
                        my $value = $args->{ $param_name };
                        $data->{ $attr_name } = \$value;
                    }
                    else {
                        $data->{ $attr_name } = $attrs->{ $attr_name }->get_initial_value_for_instance;
                    }
                }
            }
        }

        (get_stash_for( $::SELF ) || die "Could not find stash for class(" . $::SELF->get_name . ")")->bless(
            $::SELF->construct_instance( $data )
        );
    }));
    $::Class->add_method( mop::internal::method::create( name => 'FINALIZE', body => sub {
        $::SELF->set_superclass( $::Object )
            unless $::SELF->get_superclass;

        # pre-compute the vtable
        generate_stash_for( $::SELF );
    }));

    ## dispatcher

    $::Class->add_method( mop::internal::method::create( name => 'WALKMETH', body => sub {
        my ($method_name, %opts) = @_;
        $::SELF->WALKCLASS(
            sub { $_[0]->find_method( $method_name ) },
            %opts
        );
    }));
    $::Class->add_method( mop::internal::method::create( name => 'WALKCLASS', body => sub {
        my ($solver, %opts) = @_;
        my @mro = @{ $::SELF->get_mro };
        shift @mro if exists $opts{'super'};
        @mro = reverse @mro if $opts{'reverse'};
        foreach my $_class ( @mro ) {
            if ( my $result = $solver->( $_class ) ) {
                return $result;
            }
        }
        return;
    }));
    $::Class->add_method( mop::internal::method::create( name => 'DISPATCH', body => sub {
        my $method_name = shift;
        my $invocant    = shift;
        my $method = $::SELF->WALKMETH(
            $method_name
        ) || die "Could not find method '$method_name' in class(" . $::SELF->get_name . ")";
        $::SELF->CALLMETHOD( $method, $invocant, @_ );
    }));
    $::Class->add_method( mop::internal::method::create( name => 'SUBDISPATCH', body => sub {
        my $find_method = shift;
        my $reverse     = shift;
        my $invocant    = shift;
        my @args        = @_;

        $find_method = sub { $_[0]->find_method( $find_method ) }
            if !ref($find_method);

        weaken(my $self = $::SELF); # ensure the closure uses the correct one, since $::SELF is localized
        $::SELF->WALKCLASS(
            sub {
                my $method = $find_method->( $_[0] );
                $self->CALLMETHOD( $method, $invocant, @args ) if $method;
                return;
            },
            reverse => $reverse,
        );
    }));
    $::Class->add_method( mop::internal::method::create( name => 'NEXTMETHOD', body => sub {
        my $method_name = shift;
        my $invocant    = shift;
        my $method      = $::SELF->WALKMETH(
            $method_name,
            (super => 1)
        ) || die "Could not find method '$method_name'";
        $::SELF->CALLMETHOD( $method, $invocant, @_ );
    }));
    $::Class->add_method( mop::internal::method::create( name => 'CALLMETHOD', body => sub {
        my $method   = shift;
        my $invocant = shift;
        $method->execute( $invocant, @_ );
    }));
    $::Class->add_method( mop::internal::method::create( name => 'GENSTASH', body => sub {
        my $stash = Package::Anon->new( $::SELF->get_name );

        weaken(my $self = $::SELF); # ensure the closure uses the correct one, since $::SELF is localized

        $::SELF->WALKCLASS(
            sub {
                my $c = shift;
                my $methods = $c->get_methods;
                foreach my $name ( keys %$methods ) {
                    my $method = $methods->{ $name };
                    $stash->add_method( $name, sub { $self->CALLMETHOD( $method, @_ ) } )
                        unless exists $stash->{ $name };
                }
            },
        );

        $stash->add_method('NEXTMETHOD' => sub {
            my $invocant    = shift;
            my $method_name = (split '::' => ((caller(1))[3]))[-1];
            $self->NEXTMETHOD( $method_name, $invocant, @_ );
        });

        $stash->add_method('DESTROY' => sub {
            my $invocant = shift;
            $self->SUBDISPATCH(
                sub { $_[0]->get_destructor },
                0,
                $invocant,
            );
        });

        return $stash;
    }));

    ## --------------------------------
    ## $::Object
    ## --------------------------------

    $::Object->add_method( mop::internal::method::create( name => 'new', body => sub {
        my %args = @_;
        my $self = $::SELF->CREATE( \%args );
        $::SELF->SUBDISPATCH(
            sub { $_[0]->get_constructor },
            1,
            $self,
            \%args,
        );
        $self;
    }));
    $::Object->add_method( mop::internal::method::create( name => 'is_a',  body => sub { $::CLASS->equals( $_[0] ) || $::CLASS->is_subclass_of( $_[0] ) } ) );

    ## --------------------------------
    ## $::Method
    ## --------------------------------

    $::Method->add_method( mop::internal::method::create( name => 'get_name', body => sub { $::CLASS->get_slot_at( $::SELF, '$name' ) } ) );
    $::Method->add_method( mop::internal::method::create( name => 'get_body', body => sub { $::CLASS->get_slot_at( $::SELF, '$body' ) } ) );
    $::Method->add_method( mop::internal::method::create( name => 'execute', body => sub {
        my ($invocant, @args) = @_;
        mop::internal::method::execute( $::SELF, $invocant, @args );
    }));

    ## --------------------------------
    ## $::Attribute
    ## --------------------------------

    $::Attribute->add_method( mop::internal::method::create( name => 'get_name',          body => sub { $::CLASS->get_slot_at( $::SELF, '$name' ) } ) );
    $::Attribute->add_method( mop::internal::method::create( name => 'get_initial_value', body => sub { $::CLASS->get_slot_at( $::SELF, '$initial_value' ) } ) );
    $::Attribute->add_method( mop::internal::method::create( name => 'get_initial_value_for_instance', body => sub {
        my $value = ${ $::SELF->get_initial_value };

        if ( ref $value ) {
            if ( ref $value eq 'ARRAY' || ref $value eq 'HASH' ) {
                $value = Clone::clone( $value );
            }
            elsif ( ref $value eq 'CODE' ) {
                $value = $value->();
            }
            else {
                die "References of type(" . ref $value . ") are not supported";
            }
        }

        return \$value;
    }));

    ## --------------------------------
    ## make sure Class, Method and
    ## Attribute has the Object
    ## methods in the stash too
    ## --------------------------------

    {
        my $methods = mop::internal::instance::get_slot_at( $::Object, '$methods' );
        foreach my $method_name ( keys %$methods ) {
            my $method = $methods->{ $method_name };
            get_stash_for( $::Class )->add_method(
                mop::internal::instance::get_slot_at( $method, '$name' ),
                sub { mop::internal::method::execute( $method, @_ ) }
            );
            get_stash_for( $::Method )->add_method(
                mop::internal::instance::get_slot_at( $method, '$name' ),
                sub { mop::internal::method::execute( $method, @_ ) }
            );
            get_stash_for( $::Attribute )->add_method(
                mop::internal::instance::get_slot_at( $method, '$name' ),
                sub { mop::internal::method::execute( $method, @_ ) }
            );
        }
    }

    ## add enough attributes manually for add_attribute and $::Attribute->new
    ## to work

    mop::internal::instance::get_slot_at( $::Class, '$attributes' )->{'$attributes'} = mop::internal::attribute::create( name => '$attributes', initial_value => \({}) );
    mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$name'} = mop::internal::attribute::create( name => '$name', initial_value => \(my $attribute_name) );
    mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$initial_value'} = mop::internal::attribute::create( name => '$initial_value', initial_value => \(my $initial_value) );

    get_stash_for( $::Attribute )->bless( mop::internal::instance::get_slot_at( $::Class, '$attributes' )->{'$attributes'}        );
    get_stash_for( $::Attribute )->bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$name'}          );
    get_stash_for( $::Attribute )->bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$initial_value'} );

    ## add in the attributes

    $::Class->add_attribute( $::Attribute->new( name => '$name',        initial_value => \(my $class_name) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$version',     initial_value => \(my $class_version) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$authority',   initial_value => \(my $class_authority) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$superclass',  initial_value => \(my $superclass) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$methods',     initial_value => \({}) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$constructor', initial_value => \(my $constructor) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$destructor',  initial_value => \(my $destructor) ) );

    $::Method->add_attribute( $::Attribute->new( name => '$name', initial_value => \(my $method_name) ) );
    $::Method->add_attribute( $::Attribute->new( name => '$body', initial_value => \(my $method_body) ) );

    ## --------------------------------
    ## enable metaclass compatibility checks
    ## --------------------------------

    $::Class->set_constructor( $::Method->new( name => 'BUILD', body => sub {
        my $superclass = $::CLASS->get_slot_at( $::SELF, '$superclass' );
        if ( $superclass ) {
            my $compatible = $::CLASS->get_compatible_class( mop::internal::instance::get_class( $superclass ) );
            if ( !defined( $compatible ) ) {
                die "While creating class " . $::SELF->get_name . ": "
                  . "Metaclass " . $::CLASS->get_name . " is not compatible "
                  . "with the metaclass of its superclass: "
                  . mop::internal::instance::get_class( $superclass )->get_name;
            }
        }
    } ) );

    ## and, add the final, more generic version of add_method

    $::Class->add_method( $::Method->new( name => 'add_method', body => sub {
        my $method = shift;
        my $method_class = mop::internal::instance::get_class( $method );
        $::CLASS->get_slot_at( $::SELF, '$methods' )->{ $method_class->get_slot_at( $method, '$name' ) } = $method;
    }));

    ## --------------------------------
    ## END BOOTSTRAP
    ## --------------------------------

    return;
}

1;

__END__

=pod

=head1 NAME

mop::internal::boostrap

=head1 DESCRIPTION

The boostratpping process is important, but a little ugly and
manual. The main goal of the bootstrap is to define the class Class
as well as the class Object, and to "tie the knot" such that the
following things are true:

  - Class is an instance of Class
  - Object is an instance of Class
  - Class is a subclass of Object

This is what will give us our desired "turtles all the way down"
metacircularity.

-head1 TODO

These definitions should actually get stripped down to their bare
minimums so that there is less to overwrite in the MOP boostrap
that we do later on.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut