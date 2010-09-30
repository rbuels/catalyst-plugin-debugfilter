package Catalyst::Plugin::DebugFilter;
# ABSTRACT: filter Catalyst objects for cleaner debug dumps

use Moose::Role;
use Moose::Util::TypeConstraints;
use Data::Dump ();

use Data::Visitor::Callback;

=head1 SYNOPSIS

  ### in your MyApp.pm

  use Catalyst qw(
      DebugFilter
      ...
  );

  ### and in error handling code or wherever:

  # print the (filtered for readability) catalyst debugging objects in
  # plaintext, in a format similar to what appears on the default
  # Catalyst error page
  for ( $c->dump_these_strings ) {
    my ( $name, $dumped_object ) = @$_;

    print( "=== $name ===\n",
          $dumped_object,
          "\n",
         );
  }

  # filter and print some other object for debug dumping
  use Data::Dump qw/ dump /;
  print dump( $c->filter_object_for_dump( $my_object ) );

=head1 DESCRIPTION

Provides a couple of methods useful for printing readable debuggin
output.  Processes debugging objects with L<Data::Visitor::Callback>, and
exposes its flexibility with config options.

=method dump_these_strings( )

Get a list like
C<['Request', 'string dump'], ['Stash', 'string dump'], ...>
for use in debugging output.  Most users will need only this method.

=cut

sub dump_these_strings {
    my ($self) = @_;
    return
        map [ $_->[0], Data::Dump::dump( $_->[1] ) ],
        $self->dump_these_filtered;
}

=method dump_these_filtered( )

Filtered version of the L<Catalyst> C<dump_these> method.
Returns the same C<[ 'Request', $req ], ['Stash', $stash], ...>
list, except the objects in the arrayrefs are run through this
filter to make them amenable to debug dumping.

=cut

sub dump_these_filtered {
    my ($self) = @_;
    return
        map [ $_->[0], $self->filter_object_for_dump( $_->[1] ) ],
        $self->dump_these;
}


=method filter_object_for_dump( $object )

Return a filtered copy of the given object.

=cut

sub filter_object_for_dump {
    my ( $self, $object ) = @_;
    $self->debug_filter_visitor->visit( $object );
}


=attr skip_class

One or more class names to filter out of objects to be dumped.  If an
object is-a one of these classes, the dump filtering will replace
the object with a string "skipped" message.

Can be either an arrayref or a whitespace-separated list of class names.

Default: "Catalyst", which will filter out Catalyst context objects.

=attr visitor_args

Hashref of additional constructor args passed to the
L<Data::Visitor::Callback> object used to filter the objects for
dumping.  Can be used to introduce nearly any kind of additional
filtering desired.

Example:

   # replace all scalar values in dumped objects with "chicken"
   DebugFilter => {
      visitor_args => {
         value => sub { 'Chicken' },
      },
   }

=cut

{ my $sc = subtype as 'ArrayRef';
  coerce $sc, from 'Str', via { [ split ] };
  has 'skip_class' => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub { ['Catalyst'] },
   );
}

has 'visitor_args' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

=attr debug_filter_visitor

The L<Data::Visitor::Callback> object being used for filtering.  Can
be replaced with your own L<Data::Visitor> subclass if desired.

=cut

has 'debug_filter_visitor' => (
    is => 'rw',
    isa => 'Data::Visitor',
    lazy_build => 1,
   );
sub _build_debug_filter_visitor {
    my ($self) = @_;

    return Data::Visitor::Callback->new(

        # descend into objects also
        object => 'visit_ref',

        # render skip_class option as visitor args
        ( map {
            my $class = $_;
            $class => sub { shift; '('.ref(shift)." object skipped, isa $class)" }
         } @{ $self->skip_class }
        ),

        #render any other visitor args
        %{ $self->visitor_args },

       );
}

1;
