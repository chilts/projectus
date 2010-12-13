#!/usr/bin/perl
## ----------------------------------------------------------------------------

use Test::More tests => 33;
use Test::Exception;

use Projectus::Convert qw(convert_to_uid convert_ddmmyyyy_to_iso8601);

is( convert_to_uid(          ), q{}, q{empty with undef} );
is( convert_to_uid(  q{}     ), q{}, q{empty with the empty string} );
is( convert_to_uid(  q{}     ), q{}, q{empty with just spaces} );
is( convert_to_uid( qq{\t\n} ), q{}, q{empty with just whitespace} );

is( convert_to_uid( q{a}  ), q{a}, q{just 'a'} );
is( convert_to_uid( q{a-} ), q{a}, q{ends up with 'a'} );
is( convert_to_uid( q{ab} ), q{ab}, q{ends up with 'ab'} );
is( convert_to_uid( q{  a  } ), q{a}, q{starting and trailing whitespace} );
is( convert_to_uid( q{a  b} ), q{a-b}, q{whitespace in middle} );
is( convert_to_uid( q{* lots &^%$# of {}[] symbols ()=_} ), q{lots-of-symbols}, q{lots of sumbols} );
is( convert_to_uid( q{many---dashes} ), q{many-dashes}, q{many-dashes} );
is( convert_to_uid( q{--dashes-at-start-and-end---} ), q{dashes-at-start-and-end}, q{dashes at start and end} );
is( convert_to_uid( q{uppercase} ), q{uppercase}, q{Uppercase} );
is( convert_to_uid( q{Capitalised} ), q{capitalised}, q{Capitalised} );
is( convert_to_uid( q{one1} ), q{one1}, q{Numbers one} );
is( convert_to_uid( q{Numb3rs} ), q{numb3rs}, q{Numbers three} );
is( convert_to_uid( q{-dash} ), q{dash}, q{Initial Dash} );
is( convert_to_uid( qq{1one} ), q{1one}, q{initial number left ok} );
is( convert_to_uid( qq{99 Red Balloons} ), '99-red-balloons', q{99-red-balloons} );

# random stuff
is( convert_to_uid( q{^Hello, World!$} ), q{hello-world}, q{random 1} );
is( convert_to_uid( q{why do people do this} ), q{why-do-people-do-this}, q{random 2} );
is( convert_to_uid( q{alpha1} ), q{alpha1}, q{random 3} );
is( convert_to_uid( q{Alpha One} ), q{alpha-one}, q{random 4} );
is( convert_to_uid( q{Alpha 1} ), q{alpha-1}, q{random 5} );
is( convert_to_uid( q{Jossie's Giants} ), q{jossies-giants}, q{random 6} );
is( convert_to_uid( q{The Merry Go Round} ), q{the-merry-go-round}, q{random 7} );
is( convert_to_uid( q{  Hmm, this !s a b1t strange, aye!} ), q{hmm-this-s-a-b1t-strange-aye}, q{random 8} );
is( convert_to_uid( q{ P3RL^ } ), q{p3rl}, q{random 9} );

is ( convert_ddmmyyyy_to_iso8601( q{14/12/2010} ), q{2010-12-14}, q{Today} );
is ( convert_ddmmyyyy_to_iso8601( q{01/01/2010} ), q{2010-01-01}, q{First of Jan} );
is ( convert_ddmmyyyy_to_iso8601( q{02/01/2010} ), q{2010-01-02}, q{Second of Jan} );
is ( convert_ddmmyyyy_to_iso8601( q{02-01-2010} ), undef, q{Invalid format} );
is ( convert_ddmmyyyy_to_iso8601( q{29/02/2011} ), undef, q{Invalid date} );

## ----------------------------------------------------------------------------
