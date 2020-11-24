package MT::Plugin::TBPingLinkLookup;
# tb-link-lookup
# - Deny TrackBack ping which doesn't have any links to your blog.
#
# Author:  Naoya Ito <naoya at hatena.ne.jp>
#          Tatsuhiko Miyagawa <miyagawa at bulknews.net>
# License: same as Perl
#

use strict;
use base qw( MT::Plugin );

our $VERSION = "0.10";
our $PluginName = 'TBPingLinkLookup';

our $Method  = "junk"; # or moderate
our $Timeout = 5;

use MT;
use MT::Plugin;
use MT::Blog;
use MT::JunkFilter qw(ABSTAIN);

my $plugin = MT::Plugin::TBPingLinkLookup->new({
    name    => $PluginName,
    version => $VERSION,
    description => "Deny TrackBack ping which doesn't have any links to your blog.",
});

MT->add_plugin($plugin);
MT->register_junk_filter({
    name   => $PluginName,
    plugin => $plugin,
    code   => sub { $plugin->handler(@_) },
});

sub handler {
    my($plugin, $tbping) = @_;
    return ABSTAIN unless UNIVERSAL::isa($tbping,  'MT::TBPing');

    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->agent("$PluginName/$VERSION");
    $ua->timeout($Timeout);

    my $res = $ua->request(HTTP::Request->new(GET => $tbping->source_url));
    my $ok  = $res->is_success && do {
        my $url = MT::Blog->load($tbping->blog_id)->site_url;
        $res->content =~ m/\Q$url\E/;
    };

    if (!$ok) {
        if ($Method eq 'junk') {
            return (-1, "Junked Ping without links to your site");
        } elsif ($Method eq 'moderate') {
            $tbping->moderate;
            return (0,  "Moderated Ping URL without links to your site");
        }
    }

    return ABSTAIN;
}

1;
