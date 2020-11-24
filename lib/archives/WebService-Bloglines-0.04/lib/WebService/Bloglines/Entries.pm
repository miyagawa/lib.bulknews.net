package WebService::Bloglines::Entries;

use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use XML::RSS;
use XML::XPath;
use HTML::Entities;

sub parse {
    my($class, $xml) = @_;
    my $xp = XML::XPath->new(ioref => $xml);
    my $rssparent = $xp->find("/rss")->get_node(0);
    my $channelnode = $xp->find("/rss/channel");

    my @entries;
    for my $node ($channelnode->get_nodelist()) {
	my $xml = $rssparent->toString(1); # norecurse
	my $channel = $node->toString();
	$xml =~ s!</rss>$!\n$channel\n</rss>!; # wooh
	push @entries, $class->new($xml);
    }
    return wantarray ? @entries : $entries[0];
}

sub new {
    my($class, $xml) = @_;
    my $self = bless {
	_xml => $xml,
    }, $class;
    $self->_parse_xml();
    $self;
}

sub _parse_xml {
    my $self = shift;

    my $rss = XML::RSS->new();
    $rss->add_module(prefix => "bloglines", uri => "http://www.bloglines.com/services/module");
    $rss->parse($self->{_xml});
    $self->{_rss} = $rss;
}

sub feed {
    my $self = shift;
    return $self->{_rss}->{channel};
}

sub items {
    my $self = shift;
    return wantarray ? @{$self->{_rss}->{items}} : $self->{_rss}->{items};
}

1;

