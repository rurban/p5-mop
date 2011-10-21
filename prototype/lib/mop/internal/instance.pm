package mop::internal::instance;

use strict;
use warnings;

use Scalar::Footnote;
use UUID::Tiny qw/create_uuid_as_string UUID_V4/;

sub create {
    my ($class, $slots) = @_;
    my $instance = {
        %$slots,
    };
    Scalar::Footnote::set( $instance, class => $class );
    Scalar::Footnote::set( $instance, uuid  => create_uuid_as_string(UUID_V4) );
    return $instance;
}

sub get_uuid  { Scalar::Footnote::get( $_[0], 'uuid' )       }
sub get_class { ${ Scalar::Footnote::get( $_[0], 'class' ) } }
sub get_slot  { $_[0] }

sub get_slot_at {
    my ($instance, $name) = @_;
    ${ get_slot( $instance )->{ $name } || \undef }
}

sub set_slot_at {
    my ($instance, $name, $value) = @_;
    get_slot( $instance )->{ $name } = $value;
}

1;

__END__

=pod

=head1 NAME

mop::internal::instance

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut