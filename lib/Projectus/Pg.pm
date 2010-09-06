## ----------------------------------------------------------------------------

package Projectus::Pg;

use strict;
use warnings;
use Carp;
use DBI;
use Projectus::Cfg qw(get_cfg);

use base 'Exporter';
our @EXPORT_OK = qw(get_pg);

my $pg;

## ----------------------------------------------------------------------------

sub get_pg {
    my $cfg = get_cfg();

    return $pg if $pg;

    # get any config options
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
    $pg = DBI->connect(
        "dbi:Pg:dbname=$db_name",
        $db_user,
        $db_pass,
        {
            AutoCommit => 1, # act like psql
            PrintError => 0, # don't print anything, we'll do it ourselves
            RaiseError => 1, # always raise an error with something nasty
        }
    );

    return $pg;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
