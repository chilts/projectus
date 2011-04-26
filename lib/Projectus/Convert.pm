## ----------------------------------------------------------------------------

package Projectus::Convert;
use base qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(
    convert_to_uid
    convert_ddmmyyyy_to_iso8601
    convert_ddmmyyyy_to_date_simple
    convert_ymd_to_date_simple
    convert_to_boolean
    convert_to_firstname
    convert_to_lastname
    convert_to_list
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
    my ($dd, $mm, $yyyy) = $date =~ m{ \A (\d\d?)/(\d\d?)/(\d\d\d\d) \z }xms;
    return undef unless defined $dd and defined $mm and defined $yyyy;

    # fix $dd and $mm if only 1 char
    $dd = qq{0$dd} if length($dd) == 1;
    $mm = qq{0$mm} if length($mm) == 1;

    # rely on Date::Simple
    my $date = Date::Simple->new( qq{$yyyy-$mm-$dd} );
    return unless $date;
    return "$date"; # stringify the output
}

sub convert_ddmmyyyy_to_date_simple {
    my ($date) = @_;

    my $iso8601 = convert_ddmmyyyy_to_iso8601( $date );
    return undef unless $iso8601;

    return Date::Simple->new( $iso8601 );
}

sub convert_ymd_to_date_simple {
    my ($year, $month, $day) = @_;

    # make them numeric first (to remove any leading zeros)
    $year += 0;
    $month += 0;
    $day += 0;

    # add just one leading zero if necessary
    $month = $month < 10 ? q{0} . $month : $month;;
    $day = $day < 10 ? q{0} . $day : $day;

    return Date::Simple->new( qq{$year-$month-$day} );
}

sub convert_to_boolean {
    my ($boolean) = @_;

    return 0 unless defined $boolean;

    # only really check for true, anything else is false
    return 1 if exists $map->{boolean}{true}{lc $boolean};
    return 0;
}

sub convert_to_firstname {
    my ($name) = @_;
    # return '' unless defined $name;
    my ($firstname) = $name =~ m{ \A ([^\s]+) }xms;
    return '' unless defined $firstname;
    return $firstname;
}

sub convert_to_lastname {
    my ($name) = @_;
    # this just returns everything after the first set of spaces
    my ($lastname) = $name =~ m{ \A [^\s]+ \s+ (.*) \z }xms;
    return '' unless defined $lastname;
    return $lastname;
}

sub convert_to_list {
    my ($csv) = @_;

    # return empty if nothing given
    return [] unless defined $csv;

    # even if we are given a blank string such as q{ }, this is okay (it'll be
    # a one element empty string)

    my @list = split( m{ \s*,\s* }xms, $csv );
    return \@list;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
