## ----------------------------------------------------------------------------

package Projectus::Pg;

use Moose;
use Carp;
use DBI;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(get_pg get_dbh mk_std_sql_methods mk_select_list mk_select_cols mk_placeholders);

use constant NO_SLICE => { Slice => {} };
my $dbh_obj;
my @transaction;

## ----------------------------------------------------------------------------
# procedural interface

sub get_pg {
    carp "DEPRECATED: you should use get_dbh() (since this should be named as such)";
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
    my $db_tz   = $cfg->param( q{db_tz}   );

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

    # if we have a timezone, let's also set that
    $dbh_obj->do( q{SET TIMEZONE TO ?}, undef, $db_tz )
        if $db_tz;

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

# expects a hash with the following things set:
# * name   => the tablename name (str)
# * schema => the schema the table is in (str)
# * uid    => unique name (str)
# * cols   => columns which can be updated (array ref of strings)
# * ro     => read-only columns (array ref of strings)
sub mk_std_sql_methods {
    my ($self, $t) = @_;
    my $class = ref $self || $self;

    # the fqn = fully qualified name
    my $name = $t->{pseudo} || $t->{name};
    $t->{fqn} = qq{$t->{schema}.$t->{name} $t->{uid}};

    # ---
    # save the writeable cols to ->{col} so we can keep an easier check them
    foreach my $col ( @{$t->{cols}} ) {
        $t->{col}{$col} = 1;
    }

    # ---
    # create all the SQL parts
    my @cols_no_id = @{$t->{cols}};

    # generates "name, description, inserted, updated"
    $t->{sql}{list} ||= join(', ', @{$t->{cols}});

    # generates "u.id AS u_id, u.uid AS u_uid, u.description AS u_description ..."
    $t->{sql}{select} ||= mk_select_cols( $t->{uid}, @{$t->{cols}}, @{$t->{ro}} );

    # generates "u.id, u.uid, u.description ..."
    $t->{sql}{group} ||= mk_select_list( $t->{uid}, @{$t->{cols}}, @{$t->{ro}} );

    # generates "id = ?, uid = ?, description = ?, ..."
    $t->{sql}{update} ||= join(', ', map { qq{$_ = ?} } @{$t->{cols}} );

    # question marks (not the 'ro' columns, these are usually for UPDATEs)
    $t->{sql}{placeholders} ||= mk_placeholders( $t->{cols} );

    # ---
    # generate insert and delete subs
    my $method;

    # SELECT ALL: <$t->{uid}>_sel_all
    my $sql_sel_all = qq{SELECT $t->{sql}{select} FROM $t->{fqn} ORDER BY $t->{uid}.id};
    $method = sub {
        my ($self) = @_;
        # warn "sel_all($name)=$sql_sel_all";
        return $self->rows( $sql_sel_all );
    };
    $class->_inject_method( qq{${name}_sel_all}, $method );

    # SELECT: <$t->{uid}>_sel
    my $sql_sel = qq{SELECT $t->{sql}{select} FROM $t->{fqn} WHERE $t->{uid}.id = ?};
    $method = sub {
        my ($self, $id) = @_;
        # warn "sel($name)=$sql_sel";
        return $self->row( $sql_sel, $id );
    };
    $class->_inject_method( qq{${name}_sel}, $method );

    # INSERT: <$t->{uid}>_ins
    my $sql_ins = qq{INSERT INTO $t->{schema}.$name($t->{sql}{list}) VALUES($t->{sql}{placeholders})};
    $method = sub {
        my ($self, @values) = @_;
        # warn "ins($name)=$sql_ins";

        if ( ref $values[0] eq 'HASH' ) {
            my $hash = $values[0];
            my @cols;
            my @values;

            # create the SQL and insert it (but only the columns we know about)
            foreach my $col ( keys %$hash ) {
                next unless exists $t->{col}{$col};
                push @cols, $col;
                push @values, $hash->{$col};
            }
            my $sql = qq{INSERT INTO $t->{schema}.$name(} . join(', ', @cols) . q{) VALUES(} . mk_placeholders(\@cols) . q{)};
            # warn "ins($name)=$sql";
            return $self->do_sql( $sql, @values );
        }

        # do the normal insert with all the values
        return $self->do_sql( $sql_ins, @values );
    };
    $class->_inject_method( qq{${name}_ins}, $method );

    # UPDATE: <$t->{uid}>_upd
    my $sql_upd = qq{UPDATE $t->{schema}.$name SET $t->{sql}{update} WHERE id = ?};
    $method = sub {
        my ($self, $id, @values) = @_;
        # warn "upd($name)=$sql_upd";

        # warn "values[0]=" . (ref $values[0]);
        if ( ref $values[0] eq 'HASH' ) {
            my $hash = $values[0];
            my @cols;
            my @values;

            # create the SQL and update it (but only the columns we know about)
            foreach my $col ( keys %$hash ) {
                next unless exists $t->{col}{$col};
                push @cols, $col;
                push @values, $hash->{$col};
            }
            unless ( @cols ) {
                croak qq{No valid fields were found for this update: } . join(', ', sort keys %$hash);
            }

            my $sql = qq{UPDATE $t->{schema}.$name SET } . join(', ', map { qq{$_ = ?} } @cols ) . q{ WHERE id = ?};
            # warn "upd($name)=$sql";
            return $self->do_sql( $sql, @values, $id );
        }

        # else, do the normal update with all the values
        return $self->do_sql( $sql_upd, @values, $id );
    };
    $class->_inject_method( qq{${name}_upd}, $method );

    # DELETE: <$t->{uid}>_del
    my $sql_del = qq{DELETE FROM $t->{fqn} WHERE $t->{uid}.id = ?};
    $method = sub {
        my ($self, $id) = @_;
        # warn "del($name)=$sql_del";
        return $self->do_sql( $sql_del, $id );
    };
    $class->_inject_method( qq{${name}_del}, $method );

    # COUNT: <$t->{uid}>_count
    my $sql_count = qq{SELECT count(id) FROM $t->{fqn}};
    $method = sub {
        my ($self) = @_;
        # warn "sel_count($name)=$sql_count";
        return $self->rows( $sql_count );
    };
    $class->_inject_method( qq{${name}_count}, $method );
}

sub _inject_method {
    my ($class, $method_name, $method) = @_;

    # inject into package's namespace
    if ( defined &{"${class}::$method_name"} ) {
        warn qq{"${class}::$method_name" already defined, not overwriting.};
    }
    else {
        no strict 'refs';
        *{"${class}::$method_name"} = $method;
    }
}

## ----------------------------------------------------------------------------

sub register_table {
    my ($self, $name, $prefix, $pk, @cols) = @_;

    warn "Deprecated: use mk_std_sql_methods() instead!";

    $self->tables->{$name} = {
        name   => $name,
        prefix => $prefix,
        pk     => ($pk || 'id'),
        cols   => \@cols,
        sel    => mk_select_cols($prefix, @cols),
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

    # remember that we have said we want to be in a transaction
    push @transaction, scalar caller;

    # if we're already in a transaction, remember this and return
    return if $self->in_transaction;

    $self->dbh->begin_work();
}

sub rollback {
    my ($self) = @_;

    # having no transaction would be weird
    croak "Rollback called but we're not in a transaction"
        unless $self->in_transaction;

    # if we're rolling back, ignore the transaction depth and get rid of it
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

    # no more stacked transactions, so commit
    $self->dbh->commit();
}

sub in_transaction {
    my ($self) = @_;

    # When checking for whether we are in a transaction, we only ask the
    # database driver and not our @transaction stack. The reason for this is
    # because sometimes we might have called ->begin() a number of times, yet
    # if a DB query fails the driver will throw a wobbly and the transaction is
    # automatically aborted.
    #
    # Therefore, we might end up in a situation with 3 things in the
    # @transaction stack, yet we're not (in terms of the DB driver) actually in
    # a transaction.
    #
    # So here, just return what the DB driver knows is correct, rather than
    # what we _think_ is correct.

    # if AutoCommit is on, then we're not in a transaction, else we are
    return $self->dbh->{AutoCommit} ? 0 : 1;
}

# returns the last insert ID
sub id {
    my ($self, $sequence_name) = @_;
    my ($id) = $self->dbh->selectrow_array( "SELECT currval(?)", undef, $sequence_name );
    return $id;
}

sub scalar {
    my ($self, $sql, @params) = @_;
    # just return the first (and hopefully only) column/value
    return $self->dbh->selectrow_arrayref($sql, undef, @params)->[0];
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

sub do_sql {
    my ($self, $sql, @params) = @_;
    return $self->dbh->do($sql, undef, @params );
}

sub do {
    my ($self, $sql, @params) = @_;
    warn "DEPRECATED: do() ... use do_sql() instead";
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

sub ins_all {
    my ($self, $tablename, $fieldlist, $values) = @_;

    my $sql = qq{INSERT INTO $tablename};
    $sql .= q{(} . join(',', @$fieldlist) . qq{)};
    $sql .= q{ VALUES(} . join(',', map { '?' } 1 .. scalar @$fieldlist) . qq{)};

    # loop through all the data
    foreach my $row ( @$values ) {
        $self->dbh->do($sql, undef, @$row{@$fieldlist} );
    }
}

sub mk_select_list {
    my ($prefix, @cols) = @_;
    # this can be useful in GROUP BY clauses (when grouping by a whole table)
    return join(', ', map { "${prefix}_$_" } @cols );
}

sub mk_select_cols {
    my ($prefix, @cols) = @_;
    return join(', ', map { "$prefix.$_ AS ${prefix}_$_" } @cols );
}

sub mk_placeholders {
    my ($array_ref) = @_;
    return join(', ', map { '?' } @$array_ref);
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
