#!/usr/local/bin/perl
# generator.pl - Generate pretty-printedt text from url listed text files
# 
# Tatsuhiko Miyagawa <miyagawa@edge.co.jp>
# Livin' On The EDGE, Limited.
# 

use strict;
use FindBin;
use FileHandle;
use HTML::TokeParser ();
use HTML::Template;
use LWP::Simple ();
use Jcode ();

my $DEBUG = 0;

chdir $FindBin::Bin;

#--------------------------------------------------
# subs
sub fetch_title($) {
    my $uri = shift;
    my $content = LWP::Simple::get($uri);
    my $parser = HTML::TokeParser->new(\$content);
    my $token = $parser->get_tag('title');
    return $parser->get_trimmed_text('/title');
}

#--------------------------------------------------
# main
my $fh = new FileHandle;
my $tmpl = new HTML::Template filename => 'etc/reference.tmpl';

$tmpl->param(localtime => scalar(localtime(time)));

my $cat_loop;
for my $file (glob("etc/*.txt")) {
    $fh->open($file) or die "$file: $!";

    my $url_loop = [];
    while (my $line = $fh->getline) {
	chomp $line;
	next if $line =~ /^#|^\s*$/;
	print STDERR "processing $line\n" if $DEBUG;
	my $title = Jcode->new(fetch_title($line))->euc || $line;
	push @{$url_loop}, {
	    title => $title,
	    url => $line,
	};
    }
    $fh->close;

    my ($cat_name) = ($file =~ m|^etc/(.*)\.txt$|);
    push @{$cat_loop}, {
	url_loop => $url_loop,
	cat_name => $cat_name,
    };
}
$tmpl->param(cat_loop => $cat_loop);

$fh->open("> reference.html");
$fh->print($tmpl->output);
$fh->close;

    

