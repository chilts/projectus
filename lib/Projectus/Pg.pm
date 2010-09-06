## ----------------------------------------------------------------------------

package Projectus::Pg;

use Moose;
use Carp;
use DBI;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(get_pg);

use constant NO_SLICE => { Slice => {} };

## ----------------------------------------------------------------------------

has 'dbh' => (
    is      => 'rw',
    isa     => 'Any',
    default => sub {
        my $cfg = get_cfg();

        # get all the config options
        my $db_name = $cfg->param( q{db_name} );
        my $db_user = $cfg->param( q{db_user} );
        my $db_pass = $cfg->param( q{db_pass} );
        my $db_host = $cfg->param( q{db_host} );
        my $db_port = $cfg->param( q{db_port} );

        # make the connection string
        my $connect_str = qq{dbi:pg:dbname=$db_name};
        $connect_str .= qq{;host=$db_host} if $db_host;
        $connect_str .= qq{;port=$db_port} if $db_host;

        # connect to the DB
        my $dbh = DBI->connect(
            "dbi:Pg:dbname=$db_name",
            $db_user,
            $db_pass,
            {
                AutoCommit => 1, # act like psql (the spirit of least surprise)
                PrintError => 0, # don't print anything, we'll do it ourselves
                RaiseError => 1, # always raise an error with something nasty
            }
            );

        return $dbh;
    },
);

has 'tables' => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { {} }, # new hashref when created
);

## ----------------------------------------------------------------------------

sub register_table {
    my ($self, $name, $prefix, $pk, @cols) = @_;

    $self->tables->{$name} = {
        name   => $name,
        prefix => $prefix,
        pk     => ($pk || 'id'),
        cols   => \@cols,
        sel    => $self->select_cols($prefix, @cols),
    };
}

sub select_cols {
    my ($self, $prefix, @cols) = @_;
    return join(', ', map { "$prefix.$_ AS ${prefix}_$_" } @cols );
}

sub row {
    my ($self, $sql, @params) = @_;
    return $self->dbh->selectrow_hashref( $sql, undef, @params );
}

sub rows {
    my ($self, $sql, @params) = @_;
    return $self->dbh->selectall_arrayref($sql, NO_SLICE, @params );
}

sub do {
    my ($self, $sql, @params) = @_;
    return $self->dbh->do($sql, undef, @params );
}

sub sel_table {
    my ($self, $table_name) = @_;
    my $table = $self->tables->{$table_name};
    return qq{SELECT $table->{sel} FROM $table->{name} $table->{prefix} WHERE $table->{pk} = ?};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
