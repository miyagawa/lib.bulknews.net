package Template::Plugin::HTML::Template;

use strict;
use vars qw($VERSION $DYNAMIC $FILTER_NAME);
$VERSION = 0.01;

$DYNAMIC = 1;
$FILTER_NAME = 'html_template';

use HTML::Template;
use base qw(Template::Plugin::Filter);

sub init {
    my $self = shift;
    my $name = $self->{_ARGS}->[0] || $FILTER_NAME;
    $self->install_filter($name);
    return $self;
}

my $dont_use = qr/^(?:global|component|HTML|_DEBUG|_PARENT|dec|template)$/;

sub filter {
    my($self, $text, $args) = @_;
    my $template = HTML::Template->new(
	scalarref => \$text,
	die_on_bad_params => 0,
    );
    # XXX there should be a better way
    my $stash = $self->{_CONTEXT}->stash;
    my @keys = grep !/$dont_use/, keys %{$stash};
    $template->param(map { $_ => $stash->get($_) } @keys);
    return $template->output;
}

1;
__END__

=head1 NAME

Template::Plugin::HTML::Template - HTML::Template filter in TT

=head1 SYNOPSIS

  my $tt = Template->new;
  $tt->process('html-template.tt', { myname => 'foo' });

  # html-template.tt
  [% USE HTML.Template %]
  [% FILTER html_template %]
  My name is <TMPL_VAR name=myname>
  [% END %]

=head1 DESCRIPTION

Template::Plugin::HTML::Template is a TT plugin to filter
HTML::Template templates. It might sounds just silly, but it can be
handy when you want to reuse existent HTML::Template templates inside
TT.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<HTML::Template>

=cut
