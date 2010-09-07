## ----------------------------------------------------------------------------

package Projectus::Memcache;

use Moose;
use Cache::Memcached;
use Projectus::Cfg qw(get_cfg);

## ----------------------------------------------------------------------------

# single instance which all Projectus::Memcache objects share
my $memcache;

## ----------------------------------------------------------------------------

has 'memcache' => (
    is      => 'rw',
    isa     => 'Cache::Memcached',
    default => sub {
        # return the single instance if already created
        return $memcache if $memcache;

        my $cfg = get_cfg();
        my @servers = $cfg->param( q{memcache_servers} );
        my $ns = $cfg->param( q{memcache_namespace} );

        die 'No memcache servers specified'
            unless @servers;

        $memcache = Cache::Memcached->new({
            'servers'   => \@servers,
            'namespace' => $ns // '',
        });

        return $memcache;
    },
);

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
