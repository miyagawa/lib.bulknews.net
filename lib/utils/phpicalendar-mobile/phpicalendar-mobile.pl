#!/usr/local/bin/perl -w
#
# Tatsuhiko Miyagawa <miyagawa@bulknews.net>
# License: GPL2 or Artistic
#

use strict;
use CGI;
use Encode;
use LWP::Simple;
use XML::RSS;

our $UrlBase = "http://example.com/phpical/rss/rss.php?cal=...&rssview=%s&getdate=%s";
our $Charset = "Shift_JIS";

my $q = CGI->new();
   $q->charset($Charset);

my $mode = $q->param('mode') || 'week';
my $date = $q->param('date') || today();
$q->param(date => $date); # for sticky forms

my $url = sprintf $UrlBase, $mode, $date;
my $xml = LWP::Simple::get($url);

my $rss = XML::RSS->new();
   $rss->parse($xml);

print $q->header('text/html');
binmode STDOUT, ":encoding($Charset)";

print_navi($q, $mode, $date);
for my $item (@{$rss->items}) {
    $item->{title} =~ s/^.*?: //; # strip Date
    my($date, $description) = split /: /, $item->{description}, 2;
    print(
	($date ? $q->escapeHTML($date) . $q->br : ""),
	$q->escapeHTML($item->{title}), $q->br,
        ($description ? $q->escapeHTML($description) : ""), $q->hr,
    );
}

print "</body></html>";

sub print_navi {
    my($q, $nowmode, $date) = @_;
    print "<html><head><title>icalendar mobile</title></head><body>";
    print "phpicalendar", $q->hr;
    print $q->start_form({ -action => $q->script_name, -method => "GET" }),
	$q->hidden(-name => "mode", -value => $nowmode),
	$q->textfield(-name => "date", -size => 8, -istyle => 4),
        $q->submit(-value => "Go"), $q->end_form, $q->hr;
    for my $mode (qw(day week month)) {
	if ($nowmode eq $mode) {
	    print $mode, "\n";
	} else {
	    print $q->a({ -href => $q->script_name . "?mode=$mode&date=$date" }, $mode), "\n";
	}
    }
    print $q->hr;
}

sub today {
    my @time = localtime;
    return sprintf '%04d%02d%02d', $time[5]+1900, $time[4]+1, $time[3];
}
