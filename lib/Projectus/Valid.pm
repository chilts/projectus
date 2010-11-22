## ----------------------------------------------------------------------------

package Projectus::Valid;
use base qw(Exporter);

use Data::Validate::Domain qw(is_domain);
use Email::Valid;
use URI;

our @EXPORT = qw();
our @EXPORT_OK = qw(
    valid_something
    valid_int
    valid_domain
    valid_ipv4
    valid_token
    valid_url
);

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
    my ($self, $token) = @_;

    return 0 unless valid_something($token);

    # must start/end with a letter, but can have letters and -'s in the middle
    return 0 unless $token =~ m{[a-z][a-z-]*[a-z]}xms;

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

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
