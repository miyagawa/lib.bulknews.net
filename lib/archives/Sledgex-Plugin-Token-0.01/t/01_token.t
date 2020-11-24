use strict;
use Test::More 'no_plan';

use lib '../../lib';
use lib '../../t/lib';

package Mock::Pages;
use base qw(Sledge::TestPages);

use Sledgex::Plugin::Token;


use vars qw($TMPL_PATH $COOKIE_NAME);
$TMPL_PATH = 't/view';
$COOKIE_NAME = 'sid';

my $token_key;
sub dispatch_foo {
    my $self = shift;
    $token_key = $self->session->param($Sledgex::Plugin::Token::TOKEN_KEY);
    $ENV{HTTP_COOKIE} = 'sid=' . $self->session->session_id;
}

sub dispatch_bar { }

sub invalid_token {
    my($self, $token) = @_;
    die "invalid token";
}

package main;

use CGI;

{
    my $p = Mock::Pages->new();
    $p->dispatch('foo');
    like $p->output, qr/foo/;
}

{
    my $query = Sledge::Request::CGI->new(CGI->new({ token_key => $token_key }));
    my $p = Mock::Pages->new($query);
    $p->dispatch('bar');
    like $p->output, qr/bar/;
}

{
    my $query = Sledge::Request::CGI->new(CGI->new({ token_key => "zzz" }));
    my $p = Mock::Pages->new($query);
    eval { $p->dispatch('bar') };
    like $@, qr/invalid token/;
}

