package MT::Plugin::Hatena;

use strict;
use FileHandle;
use Jcode;
use LWP::UserAgent;
use URI::Escape;

our $VERSION = "1.00";

# はてなキーワードリストの API
# ローカルに保存するキャッシュファイル名
our $url       = "http://d.hatena.ne.jp/images/keyword/keywordlist";
our $cachefile = "/mt/plugins/hatenacache/keywordlist";

# MT::Template::Context から global_filter に追加する
use MT::Template::Context;
MT::Template::Context->add_global_filter(markup_hatena => \&markup_hatena);

# 正規表現をリクエスト内では使い回すためにキャッシュ
# mod_perl の場合サーバプロセスが生きている限りキャッシュ
my $regexp;

# コンテンツ本文を受けとり、はてなダイアリーのキーワードにマークアップ
sub markup_hatena {
    my $content = shift;

    # 正規表現を初期化する
    # 2度目以降はキャッシュから
    $regexp ||= init_keyword_regexp();

    if ($regexp) {
	# 本文は euc-jp に変換してからマッチさせる
	# ConfigMgr から PublishCharset を取得して Jcode で euc-jp に
	my $cfg = MT::ConfigMgr->instance;
	my $code = iana2jcode($cfg->PublishCharset);
	my $body = Jcode->new($content, $code)->euc;

	# キーワードにマッチさせて、はてなダイアリーキーワードへリンク
	$content =~ s{($regexp)}{
	    qq(<a href="http://d.hatena.ne.jp/keyword/) .
            uri_escape($1) .
	    qq(">$1</a>);
	}egio;
    };
    if ($@) {
	print STDERR "error: $@";
    }

    return $content;
}

# はてなダイアリーキーワードを取得してコンパイルしたRegexpオブジェクトを返す
sub init_keyword_regexp {
    # User-Agent: に mt-hatena とバージョン情報をセット
    my $ua  = LWP::UserAgent->new;
    $ua->agent("mt-hatena/$VERSION"); 

    # mirror メソッドで取得: Conditional GET
    my $response = $ua->mirror($url => $cachefile);
    
    # キャッシュファイルから正規表現を構築
    if (my $fh = FileHandle->new($cachefile)) {
	my $pattern = do { local $/; <$fh> };
	return qr/$pattern/;
    } else {
	die "Error while getting Hatena Keyword: ", $response->code; 
    }
}

# "euc-jp" のような IANA Charset 名から Jcode の $icode に
# 使用できるコード名に変換 デフォルトは UTF-8
sub iana2jcode {
    my $charset = shift;
    my $map = { 
	"euc-jp" => "euc", 
	"iso-2022-jp" => "jis",
	"shift_jis" => "sjis",
	"utf-8" => "utf8",
    };
    return $map->{lc($charset)} || "utf8";
}

1;
