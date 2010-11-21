#!/usr/bin/perl
## ----------------------------------------------------------------------------

use Test::More tests => 10;

use Projectus::Valid qw(valid_int);

is( valid_int(),  0, q{[undef] is not an int} );
is( valid_int(q{}),  0, q{the empty string is not an int} );
is( valid_int(q{Hello, World!}),  0, q{the empty string is not an int} );
is( valid_int(q{Five}),  0, q{the empty string is not an int} );
is( valid_int(q{5Five}),  0, q{stuff beginning with a number isn't valid} );
is( valid_int(q{Hawaii 5 Oh}),  0, q{stuff with an int in the middle isn't valid} );
is( valid_int(-1), 0, q{-1 is not an int} );

# valid values
is( valid_int(0), 1, q{0 is an int} );
is( valid_int(1), 1, q{1 is an int} );
is( valid_int(23487), 1, q{23487 is an int} );

## ----------------------------------------------------------------------------
