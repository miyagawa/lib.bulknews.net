#!/usr/local/bin/perl
# miyagawa at bulknews.net

use strict;
use DBI;
use Jcode;
use Spreadsheet::WriteExcel;

# Begin Configuration
my $DSN		= 'dbi:mysql:hoge';
my $DB_USER 	= 'root';
my $DB_PASSWD	= '';
my $XLS_FILE	= 'mysql_definition.xls';	# - for STDOUT
# End Configuration

my $dbh = DBI->connect($DSN, $DB_USER, $DB_PASSWD) or die $DBI::errstr;
my $xls = Spreadsheet::WriteExcel->new($XLS_FILE);


for my $table ($dbh->tables) {
    my $work = $xls->addworksheet("MySQL Table Definition for $table");

    $work->write(0, 0, 'INDEXES');
    my $index_ref = $dbh->selectall_arrayref("SHOW INDEX FROM $table");
    write_worksheet($work, $index_ref, 1);

    $work->write(3 + $#{$index_ref}, 0, 'COLUMNS');
    my $column_ref = $dbh->selectall_arrayref("DESCRIBE $table");
    write_worksheet($work, $column_ref, 4 + $#{$index_ref});
}

$dbh->disconnect;


sub write_worksheet {
    my($work, $ref, $offset) = @_;
    for my $row (0 .. $#{$ref}) {
	for my $col (0 .. $#{$ref->[$row]}) {
	    $work->write($row + $offset, $col, $ref->[$row]->[$col]);
	}
    }
}
