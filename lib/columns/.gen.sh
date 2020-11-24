#!/usr/local/bin/tcsh
foreach i (`ls`)
pod2html $i/column.pod >! $i/column.html
end
rm pod2html-*

