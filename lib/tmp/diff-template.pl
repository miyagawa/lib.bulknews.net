#!/usr/local/bin/perl -w
# $Id$
#
# Tatsuhiko Miyagawa <miyagawa@edge.jp>
# EDGE, Co.,Ltd.
#

use strict;
use Algorithm::Diff;
use Template::Extract;
use LWP::Simple;
use XML::RSS;
use Data::Dumper;

my $url = shift;
my $xml = LWP::Simple::get($url);

my $rss = XML::RSS->new();
$rss->parse($xml);

my $items = $rss->items;
my($doc1, $doc2) = map LWP::Simple::get($_),
    $items->[0]->{link}, $items->[1]->{link};

my($html1, $html2) = map html_arrayref($_), ($doc1, $doc2);
my @diff = Algorithm::Diff::sdiff($html1, $html2);

my $template;
my $var;
my $in_var = 0;
for my $diff (@diff) {
    if ($diff->[0] eq 'u') {
	if ($in_var) {
	    $var++;
	    $template .= "[% var$var %]\n";
	    $in_var = 0;
	}
	$template .= "$diff->[1]\n" if $diff->[1];
    } elsif ($diff->[0] eq 'c') {
	$in_var = 1;
    }
}

#warn $template;

my $e = Template::Extract->new();
my $data = $e->extract($template, $doc1);

warn Dumper $data;

sub html_arrayref {
    my $html = shift;
    return [ split /\n/, $html ];
}
