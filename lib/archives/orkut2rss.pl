#!/usr/local/bin/perl -w
# $Id$
#
# Tatsuhiko Miyagawa <miyagawa@edge.jp>
# EDGE, Co.,Ltd.
#

use strict;
use WWW::Mechanize;
use Template;

our $Username = "your-username";
our $Password = "your-password";
our $SearchId = "saved-search-name";

my @keys = qw(table image uid name attr country fans_and_path interest);

chomp(my $re = <<'RE');
(<tr style="background-color:.*?;height:80px;">
.*?<td style="width:16px;">
.*?</td><td class="C" style="width:64px;"><img src="(.*?)" border=0></td><td style="width:8px;">
.*?</td><td><a href="Profile\.aspx\?uid=(\d+)" class="P">(.*?)</a><br>(.*?)<br>(.*?)</td><td style="width:8px;">
.*?</td><td>(.*?)(?:<font class=I>interested in:</font><br>(.*?))?</td>
.*?</tr>)
RE
    ;

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $start = "http://www.orkut.com/";

my $mech = WWW::Mechanize->new();
$mech->agent_alias('Windows IE 6');

$mech->get($start);

$mech->form_number(1);

$mech->field(u => $Username);
$mech->field(p => $Password);
$mech->click();

$mech->follow_link(url_regex => qr/Search\.aspx/);

$mech->form_number(1);
$mech->field(dropdownSavedSearch => $SearchId);
{ local $^W; $mech->field(__EVENTTARGET => 'dropdownSavedSearch') }
$mech->click();

# trim CR
my $body = $mech->content();
$body =~ tr/\r//d;

my @people;
while ($body =~ /$re/gs) {
    my %data; @data{@keys} = ($1, $2, $3, $4, $5, $6, $7);
    $data{table} =~ s!(<a href|img src)="!$1="http://www.orkut.com/!g;
    push @people, \%data;
}

my $template = <<'TEMPLATE';
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:foaf="http://xmlns.com/foaf/0.1/"
 xmlns:admin="http://webns.net/mvcb/"
 xmlns="http://purl.org/rss/1.0/">
<channel rdf:about="">
  <title>orkut Search: [% id %]</title>
  <link>http://www.orkut.com/</link>
  <description>Orkut Search Results for &quot;[% id %]&quot;</description>
  <admin:generatorAgent rdf:resource="http://blog.bulknews.net/orkut2rss" />
  <items>
    <rdf:Seq>
[% FOREACH people -%]
    <rdf:li rdf:resource="http://www.orkut.com/Profile.aspx?uid=[% uid %]" />
[%- END %]
    </rdf:Seq>
  </items>
</channel>
[% FOREACH people -%]
<item rdf:about="http://www.orkut.com/Profile.aspx?uid=[% uid %]">
<title>[% name %]</title>
<link>http://www.orkut.com/Profile.aspx?uid=[% uid %]></link>
<content:encoded><![CDATA[<table>[% table %]</table>]]></content:encoded>
</item>
[%- END %]
</rdf:RDF>
TEMPLATE
    ;


my $tt = Template->new();
$tt->process(\$template, { people => \@people, id => $SearchId })
    or die $tt->error;
