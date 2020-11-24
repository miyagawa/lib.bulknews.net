#!/usr/local/bin/perl -w
# MIME メールを TypePad PhotoAlbum API でポスト

use strict;

# MIME メールをパース
use MIME::Parser;

# Atom API をラップする OO モジュール
use XML::Atom::Entry;
use XML::Atom::Client;
use XML::Atom;

# MIME B エンコード/デコード
use Encode;
use Encode::MIME::Header;

# 設定変数
# $AtomAPI: Atom API のエンドポイント
#   set_id は Photo Album の ID: 管理画面の URL から調べる
# $Username:    TypePad のユーザ名
# $Password:  TypePad のパスワード
our $AtomAPI   = "http://www.typepad.com/t/atom/gallery/set_id=7033";
our $Username  = "melody";
our $Password  = "nelson";

# .qmail ファイルとして起動
# メール本文はヘッダ込みで STDIN から取得できる
# MIME::Parser で MIME 要素をパースし画像を取り出す
my $parser = MIME::Parser->new();

# パースしたメッセージをテンポラリに出力しない
$parser->output_to_core(1);

# MIME でパースして Atom にポスト
# 例外をキャッチしたらエラー終了
eval {
    my $entity = $parser->parse(\*STDIN);
    post_to_atom($entity);
};
if ($@) {
    die "Error while posting: $@";
}

# MIME::Entity を受けとって TypePad PhotoAlbum Atom API にポスト
sub post_to_atom {
    my $entity = shift;

    # MIME::Entity から Subject, テキストパートと添付画像を取り出し
    my $subject = decode_mime_header($entity, "Subject");
    my $text    = decode("iso-2022-jp", $entity->parts(0)->bodyhandle->as_string);
    my $image   = $entity->parts(1)->bodyhandle->as_string;

    # Atom API のインタフェースとなる XML::Atom::Client
    my $api = XML::Atom::Client->new;

    # ユーザ名とパスワードをセット
    $api->username($Username);
    $api->password($Password);

    # Atom API にポストする Entry 構造体を構築
    # $image は XML::Atom で自動的に Base64 エンコードされる
    my $entry = XML::Atom::Entry->new;
    $entry->content($image);
    $entry->content->type('image/jpeg');

    # Subject を title, 本文を summary にセット
    #XXX title, summary は UTF-8 byte 文字列にしておく
    $entry->title($subject);
    $entry->summary($text);

    # エンドポイント $AtomAPI の createEntry メソッドに $entry をポスト
    # 返り値はエントリの編集を行なう URI
    my $EditAPI = $api->createEntry($AtomAPI, $entry)
        or die $api->errstr;
}

# MIME::Entity から指定したヘッダを取り出し
# MIME B デコードして Unicode 文字列として返す
sub decode_mime_header {
    my($entity, $header) = @_;
    my $value = $entity->head->get($header);

    # Encode::MIME::Header を利用して B デコード
    my $data = decode("MIME-Header", $value);
    chomp($data);
    return $data;
}
