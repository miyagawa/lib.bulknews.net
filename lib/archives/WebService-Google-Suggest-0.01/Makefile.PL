use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WebService::Google::Suggest',
    'VERSION_FROM' => 'lib/WebService/Google/Suggest.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	LWP::UserAgent => 0,
    },
);
