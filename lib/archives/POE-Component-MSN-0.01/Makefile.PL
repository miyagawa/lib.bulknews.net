use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'POE::Component::MSN',
    'VERSION_FROM' => 'lib/POE/Component/MSN.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'POE'        => 0.22,
	'Digest::MD5' => 2.20,
    },
);
