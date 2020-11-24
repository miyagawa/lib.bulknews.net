package MT::Plugin::NichTitle;
use strict;
our $VERSION = "0.02";

# http://bulkfeeds.net/app/developer.html#apikey
our $BulkfeedsAPIKey = "YOUR_API_KEY_HERE";

MT::Template::Context->add_tag(Entry2chLikeTitle => \&handle_2ch_like_title);

sub handle_2ch_like_title {
    my($ctx, $arg) = @_;
    my $entry = $ctx->stash('entry')
        or return $ctx->error("No entry for MTEntry2chLikeTitle");

    my $body = join("\n",
		    $entry->title,
		    $entry->text,
		    ($entry->text_more || ''));

    my @terms = similarity_terms($body);
    return "【$terms[0]】" . $entry->title . "【$terms[1]】";
}

use Encode::compat;
use Encode;
use HTTP::Request::Common;
use LWP::UserAgent;
use XML::Simple;

my $api = "http://bulkfeeds.net/app/terms.xml";

sub similarity_terms {
    my $body = shift;
    my $code = MT::ConfigMgr->instance->PublishCharset;
    Encode::from_to($body, $code => "utf-8");
    my $req  = POST $api, [ content => $body, apikey => $BulkfeedsAPIKey ];
    my $ua   = LWP::UserAgent->new(agent => "mt-2chtitle/$VERSION");
    my $xml  = $ua->request($req)->content;
    my $terms = XMLin($xml, ForceArray => [ "term" ])->{term};
    return map { Encode::from_to($_, "utf-8" => $code); $_ } @$terms;
}

1;

__END__

=head1 NAME

mt-2chtitle - エントリのタイトルを 2ch のニュー速風にするプラグイン

=head1 SYNOPSIS

  <$MTEntry2chLikeTitle$>

=head1 CONFIGURATION

=over 4

=item $BulkfeedsAPIKey

このプラグインの実行には Bulkfeeds API Key の取得が必要です。http://bulkfeeds.net/app/developer.html#apikey でデベロッパー登録を行い、API Key を取得し、C<$BulkfeedsAPIKey> に値をセットしてください。

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa at bulknews.netE<gt>

This code is licensed under the same terms with Perl itself (Artistic or GPL).

=cut
