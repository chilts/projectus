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
    my ($self, $view, $key, $options) = @_;

    # make the options
    my $opts = {
        key => ref $key ? JSON::Any->objToJson( $key ) : qq{"$key"},
    };
    foreach ( qw(skip limit) ) {
        $opts->{$_} = $options->{$_}
            if $options->{$_};
    }

    my $records = $self->couch->view( $view, $opts );

    my @records;
    while ( my $rec = $records->next ) {
        push @records, $rec;
    }

    return \@records;
}

sub retrieve_docs {
    my ($self, $view, $key, $options) = @_;

    # make the options
    my $opts = {
        key => ref $key ? JSON::Any->objToJson( $key ) : qq{"$key"},
        include_docs => 'true',
    };
    foreach ( qw(skip limit) ) {
        $opts->{$_} = $options->{$_}
            if $options->{$_};
    }

    my $records = $self->couch->view( $view, $opts );
    return [ map { $_->{doc} } @{$records->{data}}] ;
}

sub retrieve_doc {
    my ($self, $view, $key, $options) = @_;

    my $records = $self->retrieve_docs($view, $key, $options);

    if ( @$records > 1 ) {
        croak "You asked for 1 record, but " . (scalar @$records) . " were retrieved";
    }

    return $records->[0];
}

sub put {
    my ($self, $key, $doc) = @_;

    my $result;
    if ( $doc->{_id} and $doc->{_rev} ) {
        $result = $self->couch->update_doc( $key, $doc );
    }
    else {
        $result = $self->couch->create_named_doc( $doc, $key );
    }
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
