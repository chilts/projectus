## ----------------------------------------------------------------------------

package Projectus::Cfg;

use Moose;
use Carp;
use Config::Simple;

use base 'Exporter';
our @EXPORT_OK = qw(init_cfg get_cfg);

my $cfg_obj;

## ----------------------------------------------------------------------------
# procedural interface

# much like Log::Log4perl::init()
sub init_cfg {
    my ($filename) = @_;

    return $cfg_obj if $cfg_obj;

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
    croak q{No config loaded, you should call init_cfg($filename) before calling get_cfg()}
        unless $cfg_obj;
    return $cfg_obj;
}

## ----------------------------------------------------------------------------
# object-oriented interface

has 'cfg' => (
    is => 'rw',
    default => sub {
        my ($self) = @_;
        return $cfg_obj if defined $cfg_obj;

        # can't call init_cfg() ourselves since we don't have a $filename here
        croak "No config loaded, you should call init_cfg(...) first";
    },
);

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
