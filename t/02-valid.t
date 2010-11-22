#!/usr/bin/perl
## ----------------------------------------------------------------------------

use Test::More tests => 24;

use Projectus::Valid qw(valid_int valid_url);

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

# valid_url
is( valid_url( q{} ), 0, q{nothing} );
is( valid_url( q{google.com} ), 0, q{no scheme} );
is( valid_url( q{mailto:this@example.com} ), 0, q{emails aren't valid} );
is( valid_url( q{/just-a-path} ), 0, q{normal URL} );

is( valid_url( q{http://google.com/} ), 1, q{normal URL} );
is( valid_url( q{https://google.com/} ), 1, q{normal secure URL} );
is( valid_url( q{http://google.com} ), 1, q{no trailing slash} );
is( valid_url( q{http://hi.de.hi/} ), 1, q{sublevel domain} );
is( valid_url( q{http://google.com/?q=search} ), 1, q{with params} );
is( valid_url( q{http://google.com/} ), 1, q{with port} );
is( valid_url( q{http://google.com:80/} ), 1, q{with port} );
is( valid_url( q{http://google.com:8080/} ), 1, q{with non-standard port} );
is( valid_url( q{http://smal.ly/} ), 1, q{weird tld} );
is( valid_url( q{http://twitter.com/#!andychilton} ), 1, q{with fragment} );

## ----------------------------------------------------------------------------
