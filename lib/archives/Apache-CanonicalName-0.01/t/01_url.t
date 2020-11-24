use strict;
use Apache::Test;
use Apache::TestRequest;

plan tests => 1, have_lwp;

{
    my $body = GET_BODY "/";
    ok($body, qr!http://www.example.com:9999/bar/!);
}
