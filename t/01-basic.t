use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/lib';

use Catalyst::Test 'TestApp';

my ($r,$c) = ctx_request('/');

my @dumpthese = $c->dump_these_filtered;
is( ref, 'ARRAY', 'got arrayref' ) for @dumpthese;

@dumpthese = map { [ $_->[0], Dumper($_->[1]) ] } @dumpthese;

my $all_dumps = join '', map $_->[1], @dumpthese;

like( $all_dumps, qr/TestApp object skipped, isa Catalyst/,
      'context object filtered from dumps by default',
     );

done_testing;
