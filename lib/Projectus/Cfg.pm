## ----------------------------------------------------------------------------

package Projectus::Cfg;

use strict;
use warnings;
use Carp;
use Config::Simple;

use base 'Exporter';
our @EXPORT_OK = qw(get_cfg);

my $cfg;

## ----------------------------------------------------------------------------

sub get_cfg {
    my ($filename) = @_;

    return $cfg if $cfg;

    croak "Provide a config filename"
        unless $filename;
    croak "File does not exist: $filename"
        unless -f $filename;

    # load it up
    $cfg = Config::Simple->new( $filename );

    croak "Couldn't parse config file: " . Config::Simple->error()
        unless $cfg;

    return $cfg;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
