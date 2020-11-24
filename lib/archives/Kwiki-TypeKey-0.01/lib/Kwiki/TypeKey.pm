package Kwiki::TypeKey;
use strict;

use Kwiki::UserName '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = "0.01";

const class_id => 'user_name';
const class_title => 'Kwiki with TypeKey authentication';
const css_file => 'user_name.css';
const cgi_class => 'Kwiki::TypeKey::CGI';

sub register {
    my $registry = shift;
    $registry->add(preload => 'user_name');
    $registry->add(action  => "return_typekey");
}

sub return_typekey {
    my %cookie = map { ($_ => scalar $self->cgi->$_) } qw(email name nick ts sig);
    $self->hub->cookie->write(typekey => \%cookie);
    # XXX: Spoon doesn't write cookie in redirect!
    # $self->redirect("?" . $self->cgi->page);
    my $url = $self->config->script_name . "?" . $self->cgi->page;
    return <<HTML;
<HTML><HEAD>
<TITLE>Redirecting</TITLE>
<META HTTP-EQUIV="refresh" content="1; url=$url">
</HEAD>
<BODY onLoad="location.replace('$url')">
Redirecting you to $url</BODY></HTML>
HTML
    ;
}

package Kwiki::TypeKey::CGI;
use Kwiki::CGI '-Base';

cgi 'email';
cgi 'name';
cgi 'nick';
cgi 'ts';
cgi 'sig';
cgi 'page';

package Kwiki::TypeKey;

1;

__DATA__

=head1 NAME

Kwiki::TypeKey - Kwiki TypeKey integration

=head1 SYNOPSIS

  > $EDITOR plugins
  # Kwiki::UserName <-- If you use it, comment out
  Kwiki::TypeKey
  > $EDITOR config.yaml
  users_class: Kwiki::Users::TypeKey
  tk_token: YOUR_TYPEKEY_TOKEN
  script_name: http://www.example.com/kwiki/index.cgi <-- needs absURI
  > kwiki -update

=head1 DESCRIPTION

Kwiki::TypeKey is a Kwiki User Authentication module to use TypeKey
authentication. You need a valid TypeKey token registered at http://www.typekey.com/

=head1 TODO

=over 4

=item *

Integration with C<edit_by> link: (e.g. Kwiki::RecentChanges)

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Authen::TypeKey>

=cut

__css/user_name.css__
div #user_name_title {
  font-size: small;
  float: right;
}
__template/tt2/user_name_title.html__
<!-- BEGIN user_name_title.html -->
<div id="user_name_title">
<em>[% IF hub.users.current.name -%]
(Logged In as <a href="http://profile.typekey.com/[% hub.users.current.name %]">[% hub.users.current.nick | html %]</a>)
[%- ELSE -%]
[%- USE tk = url("https://www.typekey.com/t/typekey/login") -%] 
(Not Logged In. <a href="[% back = script_name _ "?action=return_typekey&page=" _ hub.cgi.page_name; tk(t=tk_token, v="1.1", _return=back, need_email=1) %]">Login via TypeKey</a>)
[%- END %]
</em>
</div>
<!-- END user_name_title.html -->
