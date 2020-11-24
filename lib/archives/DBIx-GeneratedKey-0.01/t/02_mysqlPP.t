use strict;
use Test::More;

use DBI;
use DBIx::GeneratedKey;

my $TestNum = 3;

my $dbh = check_env();
init_tables($dbh);

{
    my $sth = $dbh->prepare('INSERT INTO test_genkey (var) VALUES (?)');
    $sth->execute("fooof");
    my $gkey = DBIx::GeneratedKey->new($dbh);

    isa_ok $gkey, 'DBIx::GeneratedKey';
    isa_ok $gkey, 'DBIx::GeneratedKey::mysqlPP';

    is $gkey->get_generated_key, 1;
}


sub check_env {
    my $dbh;
    my $dbname = $ENV{DBD_MYSQL_DBNAME} || 'test';
    my $user   = $ENV{DBD_MYSQL_USER}   || '';
    my $passwd = $ENV{DBD_MYSQL_PASSWD} || '';
    eval {
	$dbh = DBI->connect("dbi:mysqlPP:$dbname", $user, $passwd);
    };
    plan $dbh ? (tests => $TestNum) : (skip_all => 'no mysqlPP connection');
    return $dbh;
}

sub init_tables {
    my $dbh = shift;
    $dbh->do(<<SQL);
CREATE TABLE test_genkey (
    id int unsigned not null primary key auto_increment,
    var text
)
SQL
    ;
}

END {
    if ($dbh) {
	$dbh->do('DROP TABLE test_genkey');
	$dbh->disconnect;
    }
}





