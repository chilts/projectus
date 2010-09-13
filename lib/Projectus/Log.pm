## ----------------------------------------------------------------------------

package Projectus::Log;

use Moose;
use Carp qw(croak confess);
use Log::Log4perl;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(init_log);

my $filename;

my $conf_template = q(
    log4perl.category                  = __LEVEL__, Logfile

    log4perl.appender.Logfile          = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = %d (%P) [%30.30c;%5L] %5p: %m%n
    log4perl.appender.Logfile.filename = __FILENAME__
    log4perl.appender.Logfile.mode     = append
);

## ----------------------------------------------------------------------------
# procedural interface

# much like Log::Log4perl::init()
sub init_log {
    my ($filename) = @_;

    if ( Log::Log4perl->initialized ) {
        warn "Initialising a new log when one is already initialised";
        return;
    }

    my $cfg = get_cfg();
    $filename ||= 'default.log';

    # add a .log unless it already has one
    unless ( $filename =~ m{ \.log \z }xms ) {
        $filename .= '.log';
    }

    # read some config values
    my $full_filename = $cfg->param('log_dir') . '/' . $filename;
    my $level         = $cfg->param('log_level');

    # template them in
    my $conf = $conf_template;
    $conf =~ s{__FILENAME__}{$full_filename}gxms;
    $conf =~ s{__LEVEL__}{$level}gxms;

    Log::Log4perl::init( \$conf );
};

# no such thing, since we'd just use Log::Log4perl's get_logger() anyway
# sub get_log {}

## ----------------------------------------------------------------------------
# object-oriented interface

sub BUILD {
    my ($self, $params) = @_;

    # if both of these are already set, we don't know what to do
    if ( $params->{filename} and Log::Log4perl->initialized ) {
        croak "Initialising a new log when one is already initialised isn't allowed";
    }

    # if logging is already initialised, finish here
    return if Log::Log4perl->initialized;

    # no config object, so check they provided a filename
    croak "Provide a log filename"
        unless $params->{filename};

    # initialise logging
    log_init( $params->{filename});
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
