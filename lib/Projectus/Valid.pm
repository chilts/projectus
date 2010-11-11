## ----------------------------------------------------------------------------

package Projectus::Valid;
use base qw(Exporter);

use Data::Validate::Domain qw(is_domain);
use Email::Valid;

our @EXPORT = qw();
our @EXPORT_OK = qw(
    valid_something
    valid_int
    valid_domain
    valid_ipv4
);

## ----------------------------------------------------------------------------

sub valid_something {
    my ($something) = @_;
    return unless defined $something;
    return 1 if $something =~ m{ \S }xms;
    return;
}

sub valid_int {
    my ($int) = @_;
    return 1 if $int =~ m{ \A \d+ \z }xms;
    return;
}

sub valid_domain {
    my ($domain) = @_;
    return 1 if is_domain($domain);
    return;
}

sub valid_ipv4 {
    my ($ip_address) = @_;
    my @octets = split( m{\.}xms, $ip_address );

    # check for 4 of them, between 0 and 255 inclusive
    return 0 unless @octets == 4;
    foreach my $octet ( @octets ) {
        return 0 unless $self->valid_int($octet);
        return 0 unless ( $octet >= 0 and $octet <= 255 );
    }

    return 1;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
