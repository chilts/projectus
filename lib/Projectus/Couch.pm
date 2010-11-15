## ----------------------------------------------------------------------------

package Projectus::Couch;

use Moose;
use Carp;
use Data::Dumper;
use DBI;
use JSON::Any;
use DB::CouchDB;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(get_couch);

my $couch_obj;

## ----------------------------------------------------------------------------
# procedural interface

sub get_couch {
    # return the single instance if already created
    return $couch_obj if $couch_obj;

    my $cfg = get_cfg();

    my $couch_host = $cfg->param( q{couch_host} );
    my $couch_port = $cfg->param( q{couch_port} );
    my $couch_db   = $cfg->param( q{couch_db} );

    die 'No Couch host specified'
        unless $couch_host;

    die 'No Couch DB specified'
        unless $couch_db;

    # save to the single instance
    $couch_obj = DB::CouchDB->new(
        host => $couch_host,
        ( $couch_port ? ( port => $couch_port ) : () ),
        db   => $couch_db,
    );

    return $couch_obj;
}

## ----------------------------------------------------------------------------
# object-oriented interface

has 'couch' => (
    is      => 'rw',
    isa     => 'DB::CouchDB',
    default => sub {
        return $couch_obj || get_couch();
    },
);

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
        die "You asked for 1 record, but " . (scalar @$records) . " were retrieved";
    }

    return $records->[0];
}

sub put {
    croak "This method has been deprecated";
}

# this method will just save a new version of the document. It is _your_ responsibility to
# have already retrieved the document from CouchDB since this method will croak unless
# you can supply a valid '_id' and '_key' within the $document
sub save {
    my ($self, $document) = @_;

    unless ( $document->{_id} and $document->{_rev} ) {
        croak qq{Couldn't find both the _id ($document->{_id}) or revision ($document->{_rev})};
    }

    my $result = $self->couch->update_doc( $document->{_id}, $document );
    if ( $result->err ) {
        croak qq{Couldn't save document: } . $result->errstr;
    }
    return $document;
}

# This method will make sure that whatever is in CouchDB will be
# overwritten. It does this by firstly checking CouchDB for the document and
# either putting a new one or overwriting the old one.
#
# ie. you don't have to check CouchDB yourself, this just works.
sub overwrite {
    my ($self, $id, $document) = @_;

    my $result = $self->couch->get_doc( $id );
    if ( $result->err ) {
        # no document exists yet, create it
        $result = $self->couch->create_named_doc( $document, $id );
        if ( $result->err ) {
            croak qq{Failed to create new document: } . $result->errstr;
        }

        # save these to the document
        $document->{_id} = $result->{_id};
        $document->{_rev} = $result->{_rev};
    }
    else {
        # document already exists, so use the correct _rev
        $document->{_rev} = $result->{_rev};

        # now update it in the datastore
        $result = $self->couch->update_doc( $id, $document );
        if ( $result->err ) {
            croak qq{Failed to create new document: } . $result->errstr;
        }

        # save the new _rev to the document
        $document->{_rev} = $result->{_rev};
    }
    return $document;
}

sub delete {
    my ($self, $key, $rev) = @_;
    my $result = $self->couch->delete_doc( $key, $rev );

    if ( $result->err ) {
        croak $result->err();
    }

    # copy the information out
    my %ret = %$result;
    return \%ret;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
