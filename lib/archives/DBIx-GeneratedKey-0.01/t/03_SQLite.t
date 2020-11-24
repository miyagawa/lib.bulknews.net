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
    isa_ok $gkey, 'DBIx::GeneratedKey::SQLite';

    like $gkey->get_generated_key, qr/\d/;
}


sub check_env {
    my $dbh;
    eval {
	$dbh = DBI->connect("dbi:SQLite:dbname=t/test_genkey", '', '');
    };
    plan $dbh ? (tests => $TestNum) : (skip_all => 'no SQLite connection');
    return $dbh;
}

sub init_tables {
    my $dbh = shift;
    $dbh->do(<<SQL);
CREATE TABLE test_genkey (
    id integer unsigned not null primary key,
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
    eval { unlink "t/test_genkey" };
}





