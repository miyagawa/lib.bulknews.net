use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Inline::Prolog',
    'VERSION_FROM' => 'lib/Inline/Prolog.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.18,
#	Language::Prolog => 0,
    },
);
