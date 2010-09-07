## ----------------------------------------------------------------------------

package Projectus::Couch;

use Moose;
use Data::Dumper;
use Carp;
use DBI;
use JSON::Any;
use DB::CouchDB;
use Projectus::Cfg qw(get_cfg);

## ----------------------------------------------------------------------------

# single instance which all Projectus::Couch objects share
my $couch;

## ----------------------------------------------------------------------------

has 'couch' => (
    is      => 'rw',
    isa     => 'DB::CouchDB',
    default => sub {
        # return the single instance if already created
        return $couch if $couch;

        my $cfg = get_cfg();

        my $couch_host = $cfg->param( q{couch_host} );
        my $couch_port = $cfg->param( q{couch_port} );
        my $couch_db   = $cfg->param( q{couch_db} );

        # save to the single instance
        $couch = DB::CouchDB->new(
            host => $couch_host,
            ( $couch_port ? ( port => $couch_port ) : () ),
            db   => $couch_db,
        );

        return $couch;
    },
);

## ----------------------------------------------------------------------------

sub retrieve {
    my ($self, $view, $key) = @_;

    my @records;
    my $records = $self->couch->view( $view, { key => JSON::Any->objToJson( $key ) } );
    # print Dumper($records);
    # return $records->{data};
    while ( my $rec = $records->next ) {
        # print Dumper($rec);
        push @records, $rec;
    }
    return \@records;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
