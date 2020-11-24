use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledgex::Plugin::L10N',
    'VERSION_FROM' => 'lib/Sledgex/Plugin/L10N.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
