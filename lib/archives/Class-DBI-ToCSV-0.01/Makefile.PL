use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Class::DBI::ToCSV',
    'VERSION_FROM' => 'lib/Class/DBI/ToCSV.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Text::CSV_XS => 0,
	Class::DBI => 0.90,
	IO::Scalar => 0,
    },
);
