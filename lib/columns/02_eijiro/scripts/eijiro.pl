#!/usr/local/bin/perl
# eijiro.pl - http://www.alc.co.jp/eijiro/

use strict;
use Jcode;
use LWP::Simple;
use FileHandle;
use URI::Escape;
use HTML::FormatText;
use HTML::TreeBuilder;
use Term::ReadLine;

my $historyfile = $ENV{HOME} . '/.eijirohistory';
my $pager = $ENV{PAGER} || 'less';

my $action = 'http://www.alc.co.jp/eijiro351.php3';

# Terminal mode / Argv mode
if (@ARGV) {
    my $line = join ' ', @ARGV;
    translate($line);
} else {
    my $term = Term::ReadLine->new('Eijiro');
    # read history
    if (my $fh = FileHandle->new($historyfile)) {
	my @h = $fh->getlines;
	chomp @h;
	$fh->close;
	my %seen;
	$term->addhistory($_) foreach (grep { /\S/ && !$seen{$_}++ } @h);
    }
    # readline & translate
    while ( defined ($_ = $term->readline('eijiro> ')) ) {
	exit if /^!exit/;
	translate($_);
	# Add history
	{
	    my $fh = FileHandle->new(">>$historyfile") or die $!;
	    $fh->print("$_\n");
	    $fh->close;
	}
	$term->addhistory($_) if /\S/;
    }
}

sub translate {
    my $line = shift or return;

    # ej or je
    my $type_in = $line =~ /^[\x00-\x7f]*$/ ? 'ej' : 'je';

    # URI-Escape
    my $word_in = Jcode->new($line)->sjis;
    $word_in = uri_escape($word_in, '\W');

    # get Simply
    my $url = sprintf '%s?word_in=%s&type_in=%s', $action, $word_in, $type_in;
    my $content = LWP::Simple::get($url) or die $!;
    
    my $parser = new HTML::TreeBuilder;
    my $html = $parser->parse(Jcode->new($content)->euc);
    my $format = new HTML::FormatText(leftmargin=>0);
    
    my $p = new FileHandle "| $pager";
    $p->print($format->format($html));
    $p->close;
}
