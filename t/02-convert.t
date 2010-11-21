#!/usr/bin/perl
## ----------------------------------------------------------------------------

use Test::More tests => 27;
use Test::Exception;

use Projectus::Convert qw(convert_to_uid);

throws_ok( sub { convert_to_uid(          ) }, qr{Provide a non-empty string}, q{throws with undef} );
throws_ok( sub { convert_to_uid(  q{}     ) }, qr{Provide a non-empty string}, q{throws with the empty string} );
throws_ok( sub { convert_to_uid(  q{}     ) }, qr{Provide a non-empty string}, q{throws with just spaces} );
throws_ok( sub { convert_to_uid( qq{\t\n} ) }, qr{Provide a non-empty string}, q{throws with just whitespace} );
throws_ok( sub { convert_to_uid( qq{1one} ) }, qr{start with a letter}, q{throws with an initial number} );

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

## ----------------------------------------------------------------------------
