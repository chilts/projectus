## ----------------------------------------------------------------------------

package Projectus::Redis;

use Moose;
use Redis;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(get_redis);

my $redis_obj;

## ----------------------------------------------------------------------------
# procedural interface

sub get_redis {
    # return the single instance if already created
    return $redis_obj if $redis_obj;

    my $cfg = get_cfg();
    my $redis_server = $cfg->param( q{redis_server} );

    die 'No redis server specified'
        unless $redis_server;

    $redis_obj = Redis->new({
        server => $redis_server,
    });

    return $redis_obj;
}

## ----------------------------------------------------------------------------
# object-oriented interface

has 'redis' => (
    is      => 'rw',
    isa     => 'Redis',
    default => sub {
        return $redis_obj || get_redis();
    },
);

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
