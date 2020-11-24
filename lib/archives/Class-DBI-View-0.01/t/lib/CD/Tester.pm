package CD::Tester;
use strict;
use CD::Music;

sub populate {
    my($this, $driver) = @_;
    # populate
    my @samples = (
	[ 'Ozzy Osbourne', 'Down to the Earth', 'Sony' ],
	[ 'Ozzy Osbourne', 'No More Tears', 'Sony' ],
	[ 'SLIPKNOT', 'IOWA', 'roadrunner' ],
	[ 'Aerosmith', 'Just Push Play', 'Columbia' ],
	[ 'No Use For A Name', 'UIVE IN A DIVE', 'FAT' ],
	[ 'SLAYER', 'GOD HATES US ALL', 'american' ],
    );

    for my $data (@samples) {
	my $class = "CD::Music::$driver";
	$class->create({
	    artist => $data->[0],
	    title  => $data->[1],
	    label  => $data->[2],
	});
    }
}

sub test_all {
    my($class, $strategy, $driver) = @_;
    $class->populate($driver);

    my $tester = Test::Builder->new;

    # WHERE clause
    package CD::Music::Sony;
    eval "use base qw(CD::$driver)";

    Class::DBI::View->import($strategy);

    __PACKAGE__->setup_view(<<SQL);
SELECT id, artist, title
FROM   music
WHERE  label = 'Sony'
SQL
    ;

    __PACKAGE__->columns(All => qw(id artist title));

    {
	my $iter = CD::Music::Sony->retrieve_all;
	$tester->is_num($iter->count, 2, 'count = 2');
	while (my $music = $iter->next) {
	    $tester->is_eq($music->artist, 'Ozzy Osbourne', 'artist is Ozzy');
	}
    }

    # GROUP BY
    package CD::Music::NumberOfRecords;
    eval "use base qw(CD::$driver)";

    Class::DBI::View->import($strategy);
    __PACKAGE__->setup_view(<<SQL);
SELECT artist, COUNT(artist) count
FROM music
GROUP BY artist
SQL
    ;
    __PACKAGE__->columns(All => qw(artist count));

    my @disk = sort { $b->count <=> $a->count } CD::Music::NumberOfRecords->retrieve_all;
    $tester->is_num(scalar @disk, 5, "artist is 5");

    my $first = $disk[0];
    $tester->is_eq($first->artist, 'Ozzy Osbourne', 'artist = Ozzy');
    $tester->is_num($first->count, 2, 'count = 2');

    for my $music (@disk[1..$#disk]) {
	$tester->is_num($music->count, 1, 'count = 1');
    }
}

1;
