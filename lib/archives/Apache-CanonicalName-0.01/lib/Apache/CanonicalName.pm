package Apache::CanonicalName;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

require DynaLoader;
use base qw(DynaLoader);
__PACKAGE__->bootstrap($VERSION) if $ENV{MOD_PERL};

package Apache;

sub construct_url {
    my($r, $uri) = @_;
    Apache::CanonicalName::_construct_url($r, $uri);
}

1;
__END__

=head1 NAME

Apache::CanonicalName - ap_construct_url port to mod_perl

=head1 SYNOPSIS

  # in httpd.conf
  UseCanonicalName On
  ServerName www.example.com

  # in your mod_perl handler
  use Apache::CanonicalName;

  # this module adds construct_url method to Apache
  $r->header_out(Location => $r->construct_url("/bar/"));

=head1 DESCRIPTION

Apache::CanonicalName allows you to use C<ap_construct_url> from
inside mod_perl. It constructs url correctly using C<UseCanonicalName>
configurations.

See http://httpd.apache.org/docs/mod/core.html#usecanonicalname for details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::URI>

=cut
