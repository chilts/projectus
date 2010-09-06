## ----------------------------------------------------------------------------

package Projectus::Cfg;

use strict;
use warnings;
use Carp;
use Config::Simple;

use base 'Exporter';
our @EXPORT_OK = qw(cfg_init get_cfg);

my $cfg;

## ----------------------------------------------------------------------------

sub cfg_init {
    my ($filename) = @_;

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

sub get_cfg {
    croak q{No config loaded, you should call cfg_init($filename) before calling get_cfg()}
        unless $cfg;
    return $cfg;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
