## ----------------------------------------------------------------------------

package Projectus::Pg;

use Moose;
use Carp;
use DBI;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(get_pg);

use constant NO_SLICE => { Slice => {} };
my $dbh_obj;
my @transaction;

## ----------------------------------------------------------------------------
# procedural interface

sub get_pg {
    warn "DEPRECATED: you should use get_dbh() (since this should be named as such)";
    return get_dbh();
}

sub get_dbh {
    # return the single instance if already created
    return $dbh_obj if $dbh_obj;

    my $cfg = get_cfg();

    # get all the config options
    my $db_name = $cfg->param( q{db_name} );
    my $db_user = $cfg->param( q{db_user} );
    my $db_pass = $cfg->param( q{db_pass} );
    my $db_host = $cfg->param( q{db_host} );
    my $db_port = $cfg->param( q{db_port} );

    die 'No database name specified'
        unless $db_name;

    # make the connection string
    my $connect_str = qq{dbi:Pg:dbname=$db_name};
    $connect_str .= qq{;host=$db_host} if $db_host;
    $connect_str .= qq{;port=$db_port} if $db_host;

    # connect to the DB
    $dbh_obj = DBI->connect(
        $connect_str,
        $db_user,
        $db_pass,
        {
            AutoCommit => 1, # act like psql (the spirit of least surprise)
            PrintError => 0, # don't print anything, we'll do it ourselves
            RaiseError => 1, # always raise an error with something nasty
        }
    );

    return $dbh_obj;
}

## ----------------------------------------------------------------------------
# object-oriented interface

has 'dbh' => (
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        return $dbh_obj || get_dbh();
    },
);

has 'tables' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { {} }, # new hashref when created
);

## ----------------------------------------------------------------------------
# helpers

sub _select_list {
    my ($self, $prefix, @cols) = @_;
    return join(', ', map { "${prefix}_$_" } @cols );
}

sub _select_cols {
    my ($self, $prefix, @cols) = @_;
    return join(', ', map { "$prefix.$_ AS ${prefix}_$_" } @cols );
}

sub register_table {
    my ($self, $name, $prefix, $pk, @cols) = @_;

    $self->tables->{$name} = {
        name   => $name,
        prefix => $prefix,
        pk     => ($pk || 'id'),
        cols   => \@cols,
        sel    => $self->_select_cols($prefix, @cols),
    };
}

sub table_meta {
    my ($self, $table_name) = @_;

    my $tables = $self->tables();
    unless ( exists $tables->{$table_name} ) {
        croak qq{Unknown table: $table_name};
    }

    return $tables->{$table_name};
}

sub begin {
    my ($self) = @_;

    # if we're already in a transaction, remember this and return
    if ( $self->in_transaction ) {
        push @transaction, scalar caller;
        return;
    }

    $self->dbh->begin_work();
}

sub rollback {
    my ($self) = @_;

    # if we're rolling back, ignore the transaction depth
    @transaction = ();
    $self->dbh->rollback();
}

sub commit {
    my ($self) = @_;

    # having no transaction would be weird
    croak "Commit called but we're not in a transaction"
        unless $self->in_transaction;

    # pop this transaction and if some left, just finish, else commit
    pop @transaction;
    return if @transaction;

    # no more transactions, so commit
    $self->dbh->commit();
}

sub in_transaction {
    my ($self) = @_;

    # if AutoCommit is on, then we're not in a transaction
    return if $self->dbh->{AutoCommit};

    # yes, in a transaction
    return 1;
}

# returns the last insert ID
sub id {
    my ($self, $sequence_name) = @_;
    my ($id) = $self->dbh->selectrow_array( "SELECT currval(?)", undef, $sequence_name );
    return $id;
}

sub row {
    my ($self, $sql, @params) = @_;
    return $self->dbh->selectrow_hashref( $sql, undef, @params );
}

sub rows {
    my ($self, $sql, @params) = @_;
    return $self->dbh->selectall_arrayref($sql, NO_SLICE, @params );
}

sub hash {
    my ($self, $sql, $key, @params) = @_;
    return $self->dbh->selectall_hashref($sql, $key, undef, @params);
}

sub do {
    my ($self, $sql, @params) = @_;
    return $self->dbh->do($sql, undef, @params );
}

sub sql_cols {
    my ($self, $table_name) = @_;
    return $self->tables->{$table_name}{sel};
}

sub sel_row_using_pk {
    my ($self, $table_name, $id) = @_;

    my $meta = $self->table_meta( $table_name );
    my $sql = qq{SELECT $meta->{sel} FROM $meta->{name} $meta->{prefix} WHERE $meta->{pk} = ?};

    return $self->rows( $sql, $id );
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
