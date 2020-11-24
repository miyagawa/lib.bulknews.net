package Apache::TestCanonicalName;
use strict;
use Apache::CanonicalName;

sub handler {
    my $r = shift;
    $r->send_http_header;
    $r->print($r->construct_url("/bar/"));
}

1;

