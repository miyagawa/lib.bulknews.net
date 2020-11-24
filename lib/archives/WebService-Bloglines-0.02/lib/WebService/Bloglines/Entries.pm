package WebService::Bloglines::Entries;

use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use XML::RSS;
use HTML::Entities;

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
    return @{$self->{_rss}->{items}};
}

1;

