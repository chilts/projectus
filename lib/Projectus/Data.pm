## ----------------------------------------------------------------------------

package Projectus::Data;
use base qw(Exporter);

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

## ----------------------------------------------------------------------------

sub validate {
    my ($definition, $in) = @_;

    use Data::Dumper;
    warn Dumper($definition);
    warn Dumper($in);

    # to save the errors somewhere
    my $err = {};

    # loop through each validation option and check it
    while ( my ($name, $specification) = each %$definition ) {
        my %spec = ( %$defaults, %$specification );
        my $value = $in->{$name};
        # warn "$name: $spec{type} (required=$spec{required}) - $value\n";

        # firstly, check if this is required
        if ( $spec{required} and not valid_something( $value ) ) {
            $err->{$name} = q{Required};
            next;
        }

        # looks ok, check the type (no need to check string since that's already done)
        if ( $spec{type} eq q{integer} ) {
            if ( not valid_int( $value ) ) {
                $err->{$name} = q{Invalid integer};
                next;
            }
            if ( exists $spec{min} and $value < $spec{min} ) {
                $err->{$name} = qq{Must be greater than $spec{min}};
                next;
            }
            if ( exists $spec{max} and $value > $spec{max} ) {
                $err->{$name} = qq{Must be less than $spec{max}};
                next;
            }
        }
        if ( $spec{type} eq q{email} and not valid_email( $value ) ) {
            $err->{$name} = q{Invalid email address};
            next;
        }
    }
    use Data::Dumper;
    warn Dumper($err);
    return $err;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
