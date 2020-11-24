use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Kwiki::TypeKey',
    'VERSION_FROM' => 'lib/Kwiki/TypeKey.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Authen::TypeKey => 0,
    },
);
