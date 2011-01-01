## ----------------------------------------------------------------------------

package Projectus::Valid;
use base qw(Exporter);

use Data::Validate::Domain qw(is_domain);
use Email::Valid;
use URI;
use Date::Simple;
use JSON::Any;
use Email::Valid;

our @EXPORT = qw();
our @EXPORT_OK = qw(
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

## ----------------------------------------------------------------------------
# constants

my $valid = {
    boolean => {
        map { $_ => 1 } qw(t f true false y n yes no on off 0 1)
    },
};

## ----------------------------------------------------------------------------

sub valid_something {
    my ($something) = @_;
    return 0 unless defined $something;
    return 1 if $something =~ m{ \S }xms;
    return 0;
}

sub valid_int {
    my ($int) = @_;
    return 1 if $int =~ m{ \A \d+ \z }xms;
    return 0;
}

sub valid_domain {
    my ($domain) = @_;
    return 1 if is_domain($domain);
    return 0;
}

sub valid_ipv4 {
    my ($ip_address) = @_;
    my @octets = split( m{\.}xms, $ip_address );

    # check for 4 of them, between 0 and 255 inclusive
    return 0 unless @octets == 4;
    foreach my $octet ( @octets ) {
        return 0 unless valid_int($octet);
        return 0 unless ( $octet >= 0 and $octet <= 255 );
    }

    return 1;
}

sub valid_token {
    my ($token) = @_;

    return 0 unless valid_something($token);

    # must start/end with a letter/number, but can have letters and -'s in the middle
    return 0 unless $token =~ m{ \A [a-z0-9][a-z0-9-]*[a-z0-9] \z }xms;

    # double dashes are not allowed
    return 0 if $token =~ m{--}xms;

    return 1;
}

sub valid_url {
    my ($url) = @_;

    my $uri = URI->new($url);

    # print "uri = $uri\n";
    # print "* scheme   = " . $uri->scheme . "\n";
    # print "* opaque   = " . $uri->opaque . "\n";
    # print "* path     = " . $uri->path . "\n";
    # print "* fragment = " . $uri->fragment . "\n";

    return 0 unless ( $uri->scheme eq 'http' or $uri->scheme eq 'https' );
    return 1;
}

sub valid_date {
    my ($date) = @_;

    my $date = Date::Simple->new($date);

    return 1 if $date;
    return 0;
}

sub valid_boolean {
    my ($boolean) = @_;

    return 1 if exists $valid->{boolean}{lc $boolean};
    return 0;
}

sub valid_json {
    my ($json) = @_;

    # wow, this prints some horrible stuff onto STDERR
    eval { JSON::Any->jsonToObj($json); };
    # warn $@ if $@;
    return $@ ? 0 : 1;
}

sub valid_email {
    my ($email) = @_;

    return Email::Valid->address($email) ? 1 : 0;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
