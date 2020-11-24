package MT::Plugin::BanASCII;
# mt-ban-ascii.pl
# - Deny or moderate ASCII or Latin-1 comment using MT3 CommentFilter API
#
# It requires Perl 5.8 or over.
#
# Author:  Tatsuhiko Miyagawa <miyagawa at bulknews.net>
# License: same as Perl
#

use strict;
our $VERSION = "0.91";

# 'deny' or 'moderate'
our $Method = "deny";

use MT;
use MT::Plugin;

my $plugin = MT::Plugin->new({
    name => "BanASCII v$VERSION",
    description => "Deny or moderate ASCII or Latin-1 comment",
});

MT->add_plugin($plugin);
MT->add_callback('CommentFilter', 2, $plugin, \&handler);

sub handler {
    my($eh, $app, $comment) = @_;
    require Encode;
    my $charset = MT::ConfigMgr->instance->PublishCharset;
    my $text = Encode::decode($charset, $comment->text);
    if ($text =~ /^[\x00-\xff]+$/) {
	$app->log("ASCII or Latin-1 comment from " .
		  $app->remote_ip . ": " . $Method);
	no strict 'refs';
	return $Method->($app, $comment);
    }
    return 1;
}

sub moderate {
    my($app, $comment) = @_;
    $comment->visible(0);
    return 1;
}

sub deny {
    my($app, $comment) = @_;
    return 0;
}

1;
