package XML::RSS::LibXML;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use XML::LibXML;
use XML::LibXML::XPathContext;

my $Modules = {
    'http://purl.org/rss/1.0/modules/syndication/' => 'syn',
    'http://purl.org/dc/elements/1.1/' => 'dc',
    'http://purl.org/rss/1.0/modules/taxonomy/' => 'taxo',
    'http://webns.net/mvcb/' => 'admin',
};

my $WantFields = {
    item    => [ qw(title link description content:encoded dc:date pubDate) ],
    channel => [ qw(title link description language copyright lastBuildDate generator docs
		    dc:language dc:creator dc:date admin:generatorAgent) ],
};

sub new {
    my $class = shift;
    my $self = bless {
	libxml  => XML::LibXML->new(),
	context => XML::LibXML::XPathContext->new(),
    }, $class;
    $self->_init();
    $self;
}

sub _init {
    my $self = shift;
    while (my($uri, $prefix) = each %$Modules) {
	$self->add_module(prefix => $prefix, uri => $uri);
    }
}

sub add_module {
    my($self, %param) = @_;
    $self->{context}->registerNs($param{prefix} => $param{uri});
}

sub parse {
    my($self, $string) = @_;
    $self->{doc} = $self->{libxml}->parse_string($file);
}

sub parsefile {
    my($self, $file) = @_;
    $self->{doc} = $self->{libxml}->parse_file($file);
}

sub as_string {
    my $self = shift;
    $self->{doc} ? $self->{doc}->toString(1) : undef;
}

sub channel { shift->{channel} }
sub items   { shift->{items} }

sub _parse_channel {
    my $self = shift;
    my @node = $self->{doc}->findnodes("//*[local-name()='channel']");
    $self->{context}->setContextNode($node[0]);
    $self->{channel} = $self->fetch_elem(@{$Want->{channel}});
}

sub _parse_items {
    my $self  = shift;
    my @nodes = $self->{doc}->findnodes("//*[local-name()='item']");
    for my $node (@nodes){
	$self->{context}->setContextNode($node);
	push @{$self->{items}}, $self->fetch_elem(@{$Want->{item}});
    }
}

sub fetch_elem {
    my($self, @elem) = @_;
    my $item;
    for my $elem (@elem) {
	if ($elem =~ /:/) {
	    my($prefix, $key) = split /:/, $elem;
	    $item->{$prefix}->{$key} = $self->text_element_ns($elem);
	} else {
	    $item->{$elem} = $self->text_element($elem);
	}
    }
    return $item;
}

sub text_element {
    my($self, $elem) = @_;
    return $self->{context}->findvalue("*[local-name()='$elem']/text()");
}

sub text_element_ns {
    my($self, $elem) = @_;
    return $self->{context}->findvalue("./$elem/text()");
}


1;
__END__

=head1 NAME

XML::RSS::LibXML - Use libxml2 in parsing RSS files

=head1 SYNOPSIS

  use XML::RSS::LibXML;

  my $rss = XML::RSS::LibXML->new();
  $rss->parsefile($file);

  for my $item (@{$rss->items}) {
      my $title = $item->{title};
      ## same with XML::RSS
  }

=head1 DESCRIPTION

XML::RSS::LibXML is a module that uses libxml2 in parsing RSS instead
of XML::Parser (expat). Using this module gives you a performance gain
of libxml2 while keeping interface compatiblity with XML::RSS.

=head1 COMPATIBILITY

This module is B<NOT> 100% compatible with XML::RSS. For example it
doesn't support generating RSS output. Use this module when you have a
severe requirement for performance in parsing RSS files.

=head1 BENCHMARK

TBD

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::RSS>, L<XML::LibXML>, L<XML::LibXML::XPathContext>

=cut
