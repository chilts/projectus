#!/usr/bin/perl
## ----------------------------------------------------------------------------

use Test::More tests => 42;

use Projectus::Valid qw(valid_int valid_token valid_url valid_date);

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

# valid_token
is( valid_token(), 0, q{[undef] invalid} );
is( valid_token('-'), 0, q{initial dash invalid} );
is( valid_token('double--dash'), 0, q{double dash invalid} );
is( valid_token('Hello, World!'), 0, q{random 1} );
is( valid_token('Hello'), 0, q{capital letter} );
is( valid_token('any=$=symbol'), 0, q{any symbol invalid} );
is( valid_token('trailing-dash-'), 0, q{trailing-dash invalid} );

is( valid_token('hi'), 1, q{just 'hi'} );
is( valid_token('hello-world'), 1, q{just 'hello-world'} );
is( valid_token('s-t-s-t'), 1, q{just 's-t-s-t'} );
is( valid_token('one1'), 1, q{just 'one1'} );
is( valid_token('one-1'), 1, q{just 'one-1'} );
is( valid_token('33-below'), 1, q{just '33-below'} );

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

is( valid_date( q{2010-12-14} ), 1, q{yyyy-mm-dd} );
is( valid_date( q{1976-02-29} ), 1, q{leap year} );
is( valid_date( q{14/12/2010} ), 0, q{dd/mm/yyyy} );
is( valid_date( q{14-12-2010} ), 0, q{dd-mm-yyyy} );
is( valid_date( q{2011-02-29} ), 0, q{non-leap year} );

## ----------------------------------------------------------------------------
