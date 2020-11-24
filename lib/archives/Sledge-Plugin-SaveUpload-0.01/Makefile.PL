use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Plugin::SaveUpload',
    'VERSION_FROM' => 'lib/Sledge/Plugin/SaveUpload.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
