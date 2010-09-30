package TestApp;

use Moose;
extends 'Catalyst';

use Catalyst qw/
  DebugFilter
/;

__PACKAGE__->config(
    DebugFilter => {
        skip_class => 'Catalyst',
    },
   );

__PACKAGE__->setup;

1;
