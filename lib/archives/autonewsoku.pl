#!/usr/local/bin/perl -w
# $Id$
#
# Tatsuhiko Miyagawa <miyagawa@livedoor.jp>
# Livedoor, Co.,Ltd.
#

use strict;

my $num     = 10;
my $rss_url = "http://www3.asahi.com/rss/index.rdf";

use Encode;
use encoding "utf-8", STDOUT => "euc-jp";
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::RSS;
use XML::Simple;

my $ua = LWP::UserAgent->new(agent => "autonewsoku/1.0");
my $xml = $ua->get($rss_url)->content;

my $rss = XML::RSS->new();
$rss->parse($xml);

for my $item (splice(@{$rss->items}, 0, $num)) {
    my $body = scrape_body($ua, $item->{link});
    my @terms = similar_terms($ua, $item->{title} . $body);
    print "【$terms[0]】" . $item->{title} . "【$terms[1]】\n";
}

sub similar_terms {
    my($ua, $text) = @_;
    my $req = POST "http://bulkfeeds.net/app/terms.xml",
	[ content => encode("utf-8", $text) ];
    my $res = $ua->request($req);
    my $terms = XMLin($res->content)->{term};
    return @$terms;
}

sub scrape_body {
    my($ua, $url) = @_;
    my $html = $ua->get($url)->content;
    $html =~ m/<!-- FJZONE START NAME="HONBUN"-->(.*?)<!-- FJZONE END NAME="HONBUN"-->/s;
    my $body = $1 or return;
    $body =~ s/<.*?>//g;
    Encode::_utf8_off($body);
    return decode("euc-jp", $body);
}
