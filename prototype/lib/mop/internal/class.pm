package mop::internal::class;

use strict;
use warnings;

use mop::internal::instance;

sub create {
    my %params = @_;

    my $class       = $params{'class'}       || die "A class must have a (meta) class";
    my $name        = $params{'name'}        || die "A class must have a name";
    my $version     = $params{'version'}     || undef;
    my $authority   = $params{'authority'}   || '';
    my $superclass  = $params{'superclass'}  || undef;
    my $attributes  = $params{'attributes'}  || {};
    my $methods     = $params{'methods'}     || {};
    my $constructor = $params{'constructor'} || undef;
    my $destructor  = $params{'destructor'}  || undef;

    mop::internal::instance::create(
        $class,
        {
            '$name'        => \$name,
            '$version'     => \$version,
            '$authority'   => \$authority,
            '$superclass'  => \$superclass,
            '$attributes'  => \$attributes,
            '$methods'     => \$methods,
            '$constructor' => \$constructor,
            '$destructor'  => \$destructor
        }
    );
}

1;

__END__

=pod

=head1 NAME

mop::internal::class

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut