use strict;
use Test::More;
use IO::Scalar;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DND::SQLite for testing')
	: (tests => 223);
}

use DBI;

my $DB  = "t/testdb";
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });
DBI->connect(@DSN)->do(<<SQL);
CREATE TABLE film (id INTEGER NOT NULL PRIMARY KEY, title VARCHAR(32), director VARCHAR(32), release_date DATE)
SQL
    ;

package Film;

use base qw(Class::DBI);
__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('film');
__PACKAGE__->columns(Primary => qw(id));
__PACKAGE__->columns(All => qw(title director release_date));
__PACKAGE__->columns(CSV => qw(director title));

use Class::DBI::ToCSV;

package main;
for my $i (1..50) {
    Film->create({
	title => "title $i",
	director => "director $i",
	release_date => sprintf("2003-02-%02d", $i % 31),
    });
}

use Text::CSV_XS;
my $parser = Text::CSV_XS->new({ binary => 1 });

{
    # test object method
    my $out = IO::Scalar->new(\my $csv_out);
    my $iter = Film->search_like(title => "title 1%");
    while (my $film = $iter->next) {
	$film->to_csv(All => $out);
    }

    for my $line (split /$Class::DBI::ToCSV::LineFeed/, $csv_out) {
	ok $parser->parse($line), "parse ok";
	my @columns = $parser->fields;
	is @columns, 4, '4 columns';
    }
}

{
    # test class method and group name
    my $out = IO::Scalar->new(\my $csv_out);
    Film->to_csv(CSV => $out);
    for my $line (split /$Class::DBI::ToCSV::LineFeed/, $csv_out) {
	ok $parser->parse($line), "parse ok";
	my @columns = $parser->fields;
	is @columns, 2, "2 columns";
	like $columns[0], qr/director/, "0 is director";
	like $columns[1], qr/title/, "1 is title";
    }
}

{
    # test class method and search_args
    my $out = IO::Scalar->new(\my $csv_out);
    Film->to_csv(CSV => $out, { title => 'title 1' });
    my @lines = split /$Class::DBI::ToCSV::LineFeed/, $csv_out;
    is @lines, 1, "1 lines match";
}

END { unlink $DB if -e $DB }

