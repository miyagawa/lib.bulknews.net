use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'XML::RSS::LibXML',
    'VERSION_FROM' => 'lib/XML/RSS/LibXML.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
