use strict;
use warnings;
package Catalyst::Plugin::DebugFilter;

use Moose;
use Data::Dump ();

use Data::Visitor::Callback;

extends 'SGN::View::Email';

has 'visitor_args' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

has 'skip_class' => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
   );

sub dump_these_filtered {
    my ($self) = @_;
    return map {
        $_->[1] = $self->filter_object_for_debug_dump( $_->[1] )
    } $self->dump_these;
}

has '_debug_filter_visitor' => (
    is => 'ro',
    isa => 'Data::Visitor',
    lazy_build => 1,
   );
sub _build__debug_filter_visitor {
    my ($self) = @_;

    return Data::Visitor::Callback->new(

        # descend into objects also
        object => 'visit_ref',

        # render skip_class option as visitor args
        ( map {
            my $class = $_;
            $class => sub { shift; '('.ref(shift)." skipped, isa $class)" }
         } @{ $self->skip_class }
        ),

        #render any other visitor args
        %{ $self->visitor_args },

       );
}

sub filter_object_for_debug_dump {
    my ( $self, $object ) = @_;
    $self->_debug_filter_visitor->visit( $object );
}





1;
