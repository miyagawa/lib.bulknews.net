use strict;
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DND::SQLite for testing')
	: (tests => 1);
}

use DBI;

my $DB  = "t/testdb";
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });
DBI->connect(@DSN)->do(<<SQL);
CREATE TABLE film (id INTEGER NOT NULL PRIMARY KEY, title VARCHAR(32))
SQL
    ;

package Film;

use base qw(Class::DBI);
__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('film');
__PACKAGE__->columns(Primary => qw(id));
__PACKAGE__->columns(All => qw(title));

use Class::DBI::AbstractSearch;

package main;
for my $i (1..50) {
    Film->create({
	title => "title $i",
    });
}

{
    my @films = Film->search_where(title => [ "title 10", "title 20" ]);
    is @films, 2, "films return 2";
}

END { unlink $DB if -e $DB }

