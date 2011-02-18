#!/usr/bin/perl
## ----------------------------------------------------------------------------

use Test::More tests => 1;
use Test::Exception;

use Projectus::Data qw( validate );

my $person_spec = {
    name   => { }, # all the defaults, string (required)
    sex    => { type => q{enum}, values => { male => 1, female => 1 }, required => 0, },
    email  => { type => q{email}, },
    age    => { type => q{integer}, min => 0, },
    height => { type => q{number}, min => 0, }, # 0.0, -10.8, 12.4, etc
};

my $data = {
    name   => q{Another Person},
    sex    => q{male},
    email  => q{a.person@example.net},
    age    => 35, # yrs, to neared year
    height => 176.5, # cm, to nearest cm
};

## ----------------------------------------------------------------------------

is_deeply( validate( $person_spec, $data ), {}, q{Person is OK} );

## ----------------------------------------------------------------------------
