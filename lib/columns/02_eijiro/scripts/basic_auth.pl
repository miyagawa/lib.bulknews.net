#!/usr/local/bin/perl

use strict;
use LWP::UserAgent;

my $url		= 'http://www.some.domain/auth_required/';
my $username	= 'user';
my $password	= 'XXXX';

my $ua = LWP::UserAgent->new;
my $request = HTTP::Request->new(GET => $url);
$request->authorization_basic($username, $password);
my HTTP::Response $response = $ua->request($request);

if ($response->is_success) {
    print $response->as_string;
}

