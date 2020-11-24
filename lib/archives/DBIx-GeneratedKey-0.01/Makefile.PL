use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'DBIx::GeneratedKey',
    'VERSION_FROM' => 'lib/DBIx/GeneratedKey.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
