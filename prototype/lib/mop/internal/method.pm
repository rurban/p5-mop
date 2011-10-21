package mop::internal::method;

use strict;
use warnings;

use mop::internal::instance;

use PadWalker ();
use Scope::Guard 'guard';

sub create {
    my %params = @_;

    my $name = $params{'name'} || die "A method must have a name";
    my $body = $params{'body'} || die "A method must have a body";

    mop::internal::instance::create(
        \$::Method,
        {
            '$name' => \$name,
            '$body' => \$body,
        }
    );
}

sub execute {
    my $method   = shift;
    my $invocant = shift;

    my $class = mop::internal::instance::get_class( $invocant );
    my $method_class = mop::internal::instance::get_class( $method );

    # if these are of the class $::Class, we can use the internals directly. if
    # they aren't, we have to call a method. we can't just always call a method
    # because otherwise this throws $method->execute into an infinite loop
    # (since that is itself a method call).
    # !$class can be true occasionally during global destruction
    my ($instance, $body);
    if ( !$class || ( mop::internal::instance::get_uuid( $class ) eq mop::internal::instance::get_uuid( $::Class ) ) ) {
        $instance = mop::internal::instance::get_slot( $invocant );
    }
    else {
        $instance = $class->get_slot( $invocant );
    }
    if ( !$method_class || ( mop::internal::instance::get_uuid( $method_class ) eq mop::internal::instance::get_uuid( $::Method ) ) ) {
        $body = mop::internal::instance::get_slot_at( $method, '$body' );
    }
    else {
        $body = $method_class->get_slot_at( $method, '$body' );
    }

    PadWalker::set_closed_over( $body, {
        %$instance,
        '$self'  => \$invocant,
        '$class' => \$class
    });

    my $g = guard {
        PadWalker::set_closed_over( $body, {
            (map { $_ => \undef } keys %$instance),
            '$self'  => \undef,
            '$class' => \undef,
        });
    };

    # localize the global invocant
    # and class variables here
    local $::SELF  = $invocant;
    local $::CLASS = $class;

    $body->( @_ );
}

1;

__END__

=pod

=head1 NAME

mop::internal::method

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut