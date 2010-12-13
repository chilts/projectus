## ----------------------------------------------------------------------------

package Projectus::Convert;
use base qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(
    convert_to_uid
    convert_ddmmyyyy_to_iso8601
    convert_to_boolean
);

use Projectus::Valid qw(valid_something);

## ----------------------------------------------------------------------------
# constants

my $map = {
    boolean => {
        true => { map { $_ => 1 } qw(1 t true y yes on) },
        false => { map { $_ => 1 } qw(0 f false n no off) },
    },
};

## ----------------------------------------------------------------------------

sub convert_to_uid {
    my ($something) = @_;

    return '' unless valid_something($something);

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

    return $something;
}

sub convert_ddmmyyyy_to_iso8601 {
    my ($date) = @_;

    # get what we can out of this date
    my ($dd, $mm, $yyyy) = $date =~ m{ \A (\d\d)/(\d\d)/(\d\d\d\d) \z }xms;
    return undef unless defined $dd and defined $mm and defined $yyyy;

    # rely on Date::Simple
    my $date = Date::Simple->new( qq{$yyyy-$mm-$dd} );
    return unless $date;
    return "$date"; # stringify the output
}

sub convert_to_boolean {
    my ($boolean) = @_;

    return 0 unless defined $boolean;

    # only really check for true, anything else is false
    return 1 if exists $map->{boolean}{true}{lc $boolean};
    return 0;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
