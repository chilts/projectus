## ----------------------------------------------------------------------------

package Projectus::Convert;
use base qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(
    convert_to_uid
);

use Projectus::Valid qw(valid_something);
use Carp;

## ----------------------------------------------------------------------------

sub convert_to_uid {
    my ($something) = @_;

    croak "Provide a non-empty string (ie. not undef, the empty string or just whitespace)"
        unless valid_something($something);

    # lowercase everything
    $something = lc $something;

    # convert spaces to dashes
    $something =~ s{\s}{-}gxms;

    # remove single quotes into nothing (e.g. for Jossie's Giants, isn't, can't and won't
    $something =~ s{'}{}gxms;

    # convert anything not a letter, number or dash into a dash
    $something =~ s{ [^a-z0-9-]+ }{-}gxms;

    # convert multiple dashes into just one
    $something =~ s{ -+ }{-}gxms;

    # remove start and end dashes
    $something =~ s{ \A - }{}gxms;
    $something =~ s{ - \z }{}gxms;

    croak "Must start with a letter"
        unless $something =~ m{ \A [a-z] }xms;

    croak "Provide a string with at least one letter"
        unless valid_something($something);

    return $something;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
