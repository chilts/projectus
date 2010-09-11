## ----------------------------------------------------------------------------

package Projectus::Cfg;

use Moose;
use Carp;
use Config::Simple;

use base 'Exporter';
our @EXPORT_OK = qw(cfg_init get_cfg);

my $cfg_obj;

## ----------------------------------------------------------------------------

has 'cfg' => (
    isa => 'r',
    default => sub {
        my ($self) = @_;
        return $cfg_obj if defined $cfg_obj;
        croak "No config loaded, you should call cfg_init(...) first";
    },
);

## ----------------------------------------------------------------------------

# much like Log::Log4perl::init()
sub cfg_init {
    my ($filename) = @_;

    croak "Provide a config filename"
        unless $filename;
    croak "File does not exist: $filename"
        unless -f $filename;

    # load it up
    $cfg_obj = Config::Simple->new( $filename );

    croak "Couldn't parse config file: " . Config::Simple->error()
        unless $cfg_obj;

    return $cfg_obj;
}

# much like Log::Log4perl's get_logger()
sub get_cfg {
    croak q{No config loaded, you should call cfg_init($filename) before calling get_cfg()}
        unless $cfg_obj;
    return $cfg_obj;
}

sub BUILD {
    my ($self, $params) = @_;

    # if both of these are already set, we don't know what to do
    if ( $params->{filename} and $cfg_obj ) {
        warn "Loading a new config file when one is already loaded isn't allowed";
        return;
    }

    # if config already exists, finish here
    return if $cfg_obj;

    # no config object, so check they provided a filename
    croak "Provide a config filename"
        unless $params->{filename};
    croak "File does not exist: $params->{filename}"
        unless -f $params->{filename};

    # save to the class variable
    $cfg_obj = Config::Simple->new( $params->{filename} );
}

sub hash {
    my ($self) = @_;
    my %cfg = $cfg_obj->vars();
    return \%cfg;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
