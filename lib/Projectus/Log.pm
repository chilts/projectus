## ----------------------------------------------------------------------------

package Projectus::Log;

use strict;
use warnings;
use Carp;
use Log::Log4perl;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(log_init);

## ----------------------------------------------------------------------------

my $log;
my $conf_template = q(
    log4perl.category                 = __LEVEL__, Logfile

    log4perl.appender.Logfile          = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = %d (%P) [%30.30c;%5L] %5p: %m%n
    log4perl.appender.Logfile.filename = __FILENAME__
    log4perl.appender.Logfile.mode     = append
);

sub log_init {
    my ($name) = @_;

    my $cfg = get_cfg();
    $name ||= 'default.log';

    # add a .log unless it already has one
    unless ( $name =~ m{ \.log \z }xms ) {
        $name .= '.log';
    }

    # read some config values
    my $filename = $cfg->param('log_dir') . '/' . $name;
    my $level    = $cfg->param('log_level');

    # template them in
    my $conf = $conf_template;
    $conf =~ s{__FILENAME__}{$filename}gxms;
    $conf =~ s{__LEVEL__}{$level}gxms;

    Log::Log4perl::init( \$conf );
};


## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
