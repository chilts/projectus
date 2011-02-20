## ----------------------------------------------------------------------------

package Projectus::Data;
use base qw(Exporter);
use Carp qw(croak);
use Projectus::Valid qw(
    valid_something
    valid_int
    valid_domain
    valid_ipv4
    valid_token
    valid_url
    valid_date
    valid_boolean
    valid_json
    valid_email
    valid_number
);

our @EXPORT = qw();
our @EXPORT_OK = qw(
    validate
);

## ----------------------------------------------------------------------------
# constants

my $defaults = {
    type     => q{string},
    required => 1,
};

my $types = {
    string => {
        type => q{string},
        check => sub {
            my ($value, $data) = @_;
            return q{Invalid String} unless valid_something( $value );
            return;
        },
    },
    integer => {
        type => q{integer},
        check => sub {
            my ($value, $data) = @_;
            return q{Invalid Integer} unless valid_int( $value );
            return;
        },
    },
    boolean => {
        type => q{boolean},
        check => sub {
            my ($value, $data) = @_;
            return q{Invalid Boolean} unless valid_boolean( $value );
            return;
        },
    },
    email => {
        type => q{email},
        check => sub {
            my ($value, $data) = @_;
            return q{Invalid Email Address} unless valid_email( $value );
            return;
        },
    },
    number => {
        type => q{number},
        check => sub {
            my ($value, $data) = @_;
            return q{Invalid Number} unless valid_number( $value );
            return;
        },
    },
    enum => {
        type => q{enum},
        check => sub {
            my ($value, $data) = @_;
            return q{Invalid value for Enum} unless valid_something( $value );
            return;
        },
    },
};

## ----------------------------------------------------------------------------

sub validate {
    my ($data, $definition) = @_;

    # to save the errors somewhere
    my $err = {};

    # loop through each validation option and check it
    while ( my ($name, $specification) = each %$definition ) {
        my $spec = { %$defaults, %$specification };
        my $type = $spec->{type};
        my $value = $data->{$name};

        # croak if this $type doesn't exist;
        unless ( exists $types->{$type} ) {
            croak "Invalid specification, type not known: '$type'"
        }

        ## ---
        # INTERNAL CHECKING

        # if we don't have anything, check if it's required
        unless ( valid_something( $value ) ) {
            if ( $spec->{required} ) {
                $err->{$name} = q{Required};
            }
            # we don't have anything either way, so skip it
            next;
        }

        # for the given type, do it's internal checking
        my $check = $types->{$type}{check};
        my $ret = defined $check && &$check( $value, $data );
        if ( $ret ) {
            # ie. this has returned an error string
            $err->{$name} = $err;
            next;
        }

        ## ---
        # SPECIFICATION CHECKING

        # looks ok, check the type (no need to check string since that's already done)
        if ( $type eq q{integer} ) {
            if ( exists $spec->{min} and $value < $spec->{min} ) {
                $err->{$name} = qq{Must be greater than $spec->{min}};
                next;
            }
            if ( exists $spec->{max} and $value > $spec->{max} ) {
                $err->{$name} = qq{Must be less than $spec->{max}};
                next;
            }
        }

        if ( $type eq q{enum} ) {
            # for enums, check that the value is in the list of valid values
            unless ( exists $spec->{values}{$value} ) {
                $err->{$name} = qq{Invalid value};
                next;
            }
        }

        # check specifics for other types, e.g.:
        # * if an integer has a min or max (see above)
        # * if a URI is http or https

        ## ---
        # ANONYMOUS FUNCTION CHECKING

        # finally, check their own 'check' method
        $check = $spec->{check};
        $ret = defined $check && &$check( $value, $data );
        if ( $ret ) {
            # ie. this has returned an error string
            $err->{$name} = $ret;
            next;
        }
    }

    return $err;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
