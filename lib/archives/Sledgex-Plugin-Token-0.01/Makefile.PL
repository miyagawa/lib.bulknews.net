use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledgex::Plugin::Token',
    'VERSION_FROM' => 'lib/Sledgex/Plugin/Token.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
