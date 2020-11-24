package WebService::Bloglines::Subscriptions;

use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use Encode;
use HTML::Entities;

sub new {
    my($class, $xml) = @_;
    my $self = bless {
	_xml => $xml,
	_feeds => [ ],
	_folders => { },
    }, $class;
    $self->_parse_xml();
    $self;
}

sub _parse_xml {
    my $self = shift;

    # no XML library used :-)
    my $current_folderid = 0;
    while ($self->{_xml} =~ m!(</?outline *[^>]*>)!gs) {
	local $_ = $1;
	tr/\n//d;
	if (m!^<outline (.*?)/>$!) {
	    my $attr = $self->_parse_attr($1);
	    $attr->{folderId} = $current_folderid;
	    push @{$self->{_feeds}}, $attr;
	} elsif (m!<outline (.*?)>$!) {
	    my $attr = $self->_parse_attr($1);
	    next unless $attr->{BloglinesSubId};
	    $self->{_folders}->{$attr->{BloglinesSubId}} = $attr;
	    $current_folderid = $attr->{BloglinesSubId};
	} elsif (m!^</outline>$!) {
	    $current_folderid = 0;
	} else {
#	    warn "No match: $_";
	}
    }
}

sub _parse_attr {
    my($self, $attrline) = @_;
    my %attr;
    while ($attrline =~ s/\s*(\w+)="([^\"]*)"//) {
	$attr{$1} = Encode::decode("utf-8", HTML::Entities::decode($2));
    }
    return \%attr;
}

sub feeds {
    my $self = shift;
    return @{$self->{_feeds}};
}

sub folders {
    my $self = shift;
    return sort { $a->{BloglinesSubId} <=> $b->{BloglinesSubId} } values %{$self->{_folders}};
}

sub feeds_in_folder {
    my($self, $subid) = @_;
    $subid ||= 0;
    return grep { $_->{folderId} == $subid } $self->feeds();
}

1;

