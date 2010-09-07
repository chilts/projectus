## ----------------------------------------------------------------------------

package Projectus::Redis;

use Moose;
use Redis;
use Projectus::Cfg qw(get_cfg);

## ----------------------------------------------------------------------------

# single instance which all Projectus::Redis objects share
my $redis;

## ----------------------------------------------------------------------------

has 'redis' => (
    is      => 'rw',
    isa     => 'Redis',
    default => sub {
        # return the single instance if already created
        return $redis if $redis;

        my $cfg = get_cfg();
        my $redis_server = $cfg->param( q{redis_server} );

        die 'No redis server specified'
            unless $redis_server;

        $redis = Redis->new({
            server => $redis_server,
        });

        return $redis;
    },
);

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
