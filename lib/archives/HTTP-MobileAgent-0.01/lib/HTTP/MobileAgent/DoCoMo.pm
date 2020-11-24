package HTTP::MobileAgent::DoCoMo;

use strict;
use base qw(HTTP::MobileAgent);

__PACKAGE__->make_accessors(
    qw(version model status bandwidth
       serial_number is_foma card_id comment)
);

# various preferences
use vars qw($DefaultCacheSize $HTMLVerMap $FOMAHTMLVersion);
$DefaultCacheSize = 5;
$FOMAHTMLVersion  = '3.0';

# http://www.nttdocomo.co.jp/p_s/imode/spec/useragent.html
$HTMLVerMap = [
    # regex => version
    qr/[DFNP]501i/ => '1.0',
    qr/502i|821i|209i|691i|(F|N|P|KO)210i|^F671i$/ => '2.0',
    qr/(D210i|SO210i)|503i|211i|SH251i|692i/ => '3.0',
    qr/504i|[DF]251i|^F671iS$/ => '4.0',
    qr/eggy|P751v/ => '3.2',
];


sub parse {
    my $self = shift;
    my($main, $foma_or_comment) = split / /, $self->user_agent, 2;

    if ($foma_or_comment && $foma_or_comment =~ s/^\((.*)\)$/$1/) {
	# DoCoMo/1.0/P209is (Google CHTML Proxy/1.0)
	$self->{comment} = $1;
	$self->_parse_main($main);
    } elsif ($foma_or_comment) {
	# DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)
	$self->{is_foma} = 1;
	@{$self}{qw(name version)} = split m!/!, $main;
	$self->_parse_foma($foma_or_comment);
    } else {
	# DoCoMo/1.0/R692i/c10
	$self->_parse_main($main);
    }
}

sub _parse_main {
    my($self, $main) = @_;
    my($name, $version, $model, $cache, @rest) = split m!/!, $main;
    $self->{name}    = $name;
    $self->{version} = $version;
    $self->{model}   = $model;

    if ($cache) {
	$cache =~ s/^c// or return $self->no_match;
	$self->{cache_size} = $cache;
    }

    for (@rest) {
	/^ser(\w{11})$/ and do { $self->{serial_number} = $1; next };
	/^(T[DBJ])$/   and do { $self->{status} = $1; next };
	/^s(\d+)$/     and do { $self->{bandwidth} = $1; next };
    }
}

sub _parse_foma {
    my($self, $foma) = @_;

    $foma =~ s/^([^\(]+)// or return $self->no_match;
    $self->{model} = $1;
    $self->{model} = 'SH2101V' if $1 eq 'MST_v_SH2101V'; # Huh?

    if ($foma =~ s/^\((.*?)\)$//) {
	my($cache, $serial, $icc) = split /;/, $1;
	$self->{cache_size} = substr($cache, 1);
	if ($serial) {
	    $serial =~ s/^ser(\w{15})$/$1/ or return $self->no_match;
	    $self->{serial_number} = $serial;
	}
	if ($icc) {
	    $icc =~ s/^icc(\w{20})$/$1/ or return $self->no_match;
	    $self->{card_id} = $icc;
	}
    }
}

sub is_docomo { 1 }

sub html_version {
    my $self = shift;
    return $FOMAHTMLVersion if $self->is_foma;

    my @map = @$HTMLVerMap;
    while (my($re, $version) = splice(@map, 0, 2)) {
	return $version if $self->model =~ /$re/;
    }
    return undef;
}

sub cache_size {
    my $self = shift;
    return $self->{cache_size} || $DefaultCacheSize;
}

sub series {
    my $self = shift;
    return 'FOMA' if $self->is_foma;

    my $model = $self->model;
    $model =~ /(\d{3}i)/;
    return $1;
}

sub vendor {
    my $self = shift;
    my $model = $self->model;
    $model =~ /^([A-Z]+)\d/;
    return $1;
}

1;
__END__

=head1 NAME

HTTP::MobileAgent::DoCoMo - NTT DoCoMo implementation

=head1 SYNOPSIS

  use HTTP::MobileAgent;

  local $ENV{HTTP_USER_AGENT} = "DoCoMo/1.0/P502i/c10";
  my $agent = HTTP::MobileAgent->new;

  printf "Name: %s\n", $agent->name;       		# "DoCoMo"
  printf "Ver: %s\n", $agent->version; 			# 1.0
  printf "HTML ver: %s\n", $agent->html_version;	# 2.0
  printf "Model: %s\n", $agent->model;			# "P502i"
  printf "Cache: %dk\n", $agent->cache_size;		# 10
  print  "FOMA\n" if $agent->is_foma;			# false
  printf "Vendor: %s\n", $agent->vendor;		# 'P'
  printf "Series: %s\n", $agent->series;		# "502i"

  # only available with <form utn>
  # e.g.) "DoCoMo/1.0/P503i/c10/serNMABH200331";
  printf "Serial: %s\n", $agent->serial_number;		# "NMABH200331"

  # e.g.) "DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)";
  printf "Serial: %s\n", $agent->serial_number;		# "0123456789abcde"
  printf "Card ID: %s\n", $agent->card_id;		# "01234567890123456789"

  # e.g.) "DoCoMo/1.0/P502i (Google CHTML Proxy/1.0)
  pritnf "Comment: %s\n", $agent->comment;		# "Google CHTML Proxy/1.0

  # only available in eggy/M-stage
  # e.g.) "DoCoMo/1.0/eggy/c300/s32/kPHS-K"
  printf "Bandwidth: %dkbps\n", $agent->bandwidth;	# 32

=head1 DESCRIPTION

HTTP::MobileAgent::DoCoMo is a subclass of HTTP::MobileAgent, which
implements NTT docomo i-mode user agents.

=head1 METHODS

See L<HTTP::MobileAgent/"METHODS"> for common methods. Here are
HTTP::MobileAgent::DoCoMo specific methods.

=over 4

=item version

  $version = $agent->version;

returns DoCoMo version number like "1.0".

=item html_version

  $html_version = $agent->html_version;

returns supported HTML version like '3.0'. retuns undef if unknown.

=item model

  $model = $agent->model;

returns name of the model like 'P502i'.

=item cache_size

  $cache_size = $agent->cache_size;

returns cache size as killobytes unit. returns 5 if unknown.

=item is_foma

  if ($agent->is_foma) { }

retuns whether it's FOMA or not.

=item vendor

  $vendor = $agent->vendor;

returns vender code like 'SO' for Sony. returns undef if unknown.

=item series

  $series = $agent->series;

returns series name like '502i'. returns undef if unknown.

=item serial_number

  $serial_number = $agent->serial_number;

returns hardware unique serial number (15 digit in FOMA, 11 digit
otherwise alphanumeric). Only available with E<lt>form utnE<gt>
attribute. returns undef otherwise.

=item card_id

  $card_id = $agent->card_id;

returns FOMA Card ID (20 digit alphanumeric). Only available in FOMA
with E<lt>form utnE<gt> attribute. returns undef otherwise.

=item comment

  $comment = $agent->comment;

returns comment on user agent string like 'Google Proxy'. returns
undef otherwise.

=item bandwidth

  $bandwidth = $agent->bandwidth;

returns bandwidth like 32 as killobytes unit. Only vailable in eggy,
returns undef otherwise.

=back

=head1 TODO

=over 4

=item *

Region and screen size support availabe at
http://www.nttdocomo.co.jp/p_s/imode/spec/ryouiki.html

(Patches are always welcome ;))

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::MobileAgent>

http://www.nttdocomo.co.jp/p_s/imode/spec/useragent.html

http://www.nttdocomo.co.jp/p_s/imode/spec/ryouiki.html

http://www.nttdocomo.co.jp/p_s/imode/tag/utn.html

http://www.nttdocomo.co.jp/p_s/mstage/visual/contents/cnt_mpage.html


=cut
