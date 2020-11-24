package Sledgex::Plugin::Token;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use vars qw($TOKEN_KEY);
$TOKEN_KEY = 'token_key';

use Time::HiRes qw(gettimeofday);

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    return unless $pkg->isa('Sledge::Pages::Base');

    $pkg->register_hook(
	BEFORE_DISPATCH => sub {
	    my $self = shift;
	    my $supplied = $self->r->param($TOKEN_KEY);
	    my $server   = $self->session->param($TOKEN_KEY);

	    if ($supplied && $server && $supplied ne $server) {
		return $self->invalid_token($server);
	    }
	    my $new_key = _get_new_token($self);
	    $self->session->param($TOKEN_KEY => $new_key);
	    $self->tmpl->param($TOKEN_KEY => $new_key);
	    $self->fillin_form->ignore_fields([ $TOKEN_KEY ]) if $self->fillin_form;
	},
    );
}


sub _get_new_token {
    my $self = shift;
    return $ENV{UNIQUE_ID} || gettimeofday();
}

1;
__END__

=head1 NAME

Sledgex::Plugin::Token - Token validation to protect "back-button problem"

=head1 SYNOPSIS

  package Project::Pages;
  use Sledgex::Plugin::Token;

  # in your template
  <input type="hidden" name="token_key" value="[% token_key %]">

=head1 DESCRIPTION

Sledgex::Plugin::Token is a Sledge (experimental) plugin to protect
"back-button" problem.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@edge.co.jpE<gt>

=head1 SEE ALSO

L<Sledge::Pages::Base>

=cut
