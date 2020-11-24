use strict;
use Test::More tests => 4;

BEGIN { use_ok 'WebService::Google::Suggest' }

my $suggest = WebService::Google::Suggest->new();

isa_ok($suggest->ua, "LWP::UserAgent", "ua() retuens LWP");

my @data = $suggest->complete("google");
is($data[0]->{query}, "google", "google completes to google");
is_deeply( [ $suggest->complete("udfg67a") ], [ ], "empty list" );

