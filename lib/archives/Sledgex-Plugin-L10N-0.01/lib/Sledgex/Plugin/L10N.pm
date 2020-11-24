package Sledgex::Plugin::L10N;
# $Id: L10N.pm,v 1.2 2002/10/20 14:59:46 miyagawa Exp $

use strict;
use vars qw($VERSION $DEBUG);
$VERSION = 0.01;

use base qw(Class::Data::Inheritable);

use Data::Dumper;
use HTTP::Negotiate;
use Sledgex::Charset::L10N;

$DEBUG = 0;

sub import {
    my $class = shift;
    my $pkg   = caller(0);

    # set up class data
    $pkg->mk_classdata('languages');
    $pkg->languages({});

    no strict 'refs';
    for my $method (qw(guess_filename)) {
	*{"$pkg\::$method"} = \&$method;
    }
}

sub guess_filename {
    my $self = shift;
    my @prefered = choose_language($self);
    warn "prefered languages are: ", Dumper(\@prefered) if $DEBUG;

    my $filename = $self->Sledge::Pages::Base::guess_filename(@_);
    unless ($prefered[0]->[1] >= 0.001) {
	warn "no language is more than q=0.001. return default: $filename\n" if $DEBUG;
	return $filename;
    }

    my($path, $ext) = $filename =~ /^(.*)\.([a-z]+)$/;
    for my $pref (@prefered) {
	my $l10n = "$path.$pref->[0].$ext";
	if (-e $l10n) {
	    warn "template found for lang: $pref->[0]\n" if $DEBUG;
	    $self->charset->charset($self->languages->{$pref->[0]}->{charset});
	    return $l10n;
	}
	warn "template not found for lang: $pref->[0]\n" if $DEBUG;
    }

    # template file not found
    warn "l10n template not found. return default: $filename\n" if $DEBUG;
    return $filename;
}

sub choose_language {
    my $self = shift;
    my $lang = $self->languages;

    my @variants = map {
	# ID QS Content-Type Encoding Char-Set Lang Size
	[ $_, $lang->{$_}->{quality} || 0.5, 'text/html', undef, $lang->{$_}->{charset}, $_, undef ];
    } keys %$lang;

    return HTTP::Negotiate::choose(\@variants);
}

1;

__END__

=head1 NAME

Sledgex::Plugin::L10N - L10N framework for Sledge

=head1 SYNOPSIS

  package Your::Pages;
  use Sledgex::Plugin::L10N;

  __PACKAGE__->languages({
      ja => { charset => 'euc-jp', quality => 1.0, }, # q=0.5 by default
      en => { charset => 'us-ascii' },
      de => { charset => 'iso-8859-1' },
  });

  sub create_charset {
      my $self = shift;
      return Sledgex::Charset::L10N->new($self);
  }

=head1 DESCRIPTION

Sledgex::Plugin;:L10N is an experimental L10N (localization) framework
for Sledge Hammer.

Content negotiation algorith is based on HTTP::Negotiate module, which
is a little complicated. See C<t/01_negotiate.t> for examples.

=head1 TODO

=over 4

=item *

language handle using C<Locale::Maketext>.

=item *

blow away C<HTTP::Negotiate> dependency to ::L10N::Negotiation or so.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Sledge::Template::L10N>, L<Sledge::Charset::L10N>

=cut
