## ----------------------------------------------------------------------------

package Projectus::Memcache;

use Moose;
use Cache::Memcached;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(get_memcache);

my $memcache_obj;

## ----------------------------------------------------------------------------
# procedural interface

sub get_memcache {
    # return the single instance if already created
    return $memcache_obj if $memcache_obj;

    my $cfg = get_cfg();
    my @servers = $cfg->param( q{memcache_servers} );
    my $ns = $cfg->param( q{memcache_namespace} );

    die 'No memcache servers specified'
        unless @servers;

    $memcache_obj = Cache::Memcached->new({
        servers   => \@servers,
        namespace => $ns // '',
    });

    return $memcache_obj;
}

## ----------------------------------------------------------------------------
# object-oriented interface

has 'memcache' => (
    is      => 'rw',
    isa     => 'Cache::Memcached',
    default => sub {
        my ($self) = @_;
        return $memcache_obj || get_memcache();
    },
);

sub inc_key {
    die "ToDo";
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
