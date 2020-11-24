use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WebService::Bloglines',
    'VERSION_FROM' => 'lib/WebService/Bloglines.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	LWP => 0,
	XML::RSS => 0,
    },
);
