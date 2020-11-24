#!/usr/local/bin/perl
use strict;
use CGI;
use Jcode;
use WWW::Baseball::NPB;
use XML::RSS;

do_task(CGI->new);

sub do_task {
    my $query = shift;
    my $rss   = XML::RSS->new(
       version => 1.0,
       encoding => 'utf-8',
    );
    $rss->channel(title => 'WWW::Baseball::NPB demo',
		  link  => 'http://sports.yahoo.co.jp/baseball/');
    my $bb    = WWW::Baseball::NPB->new;
    my @games = $bb->games;
    for my $game (@games) {
	my $home    = $game->home;
	my $visitor = $game->visitor;
	my $title = sprintf "%s %s - %s %s (%s) [%s]\n",
        $home, $game->score($home), $game->score($visitor),
            $visitor, $game->status, $game->stadium;
	$rss->add_item(title => $title);
    }
    unless (@games) {
	$rss->add_item(title => '今日の試合はありません');
    }
    print $query->header('text/xml; charset=utf-8'), Jcode->new($rss->as_string)->utf8;
}

