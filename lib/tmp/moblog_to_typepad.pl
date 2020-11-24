#!/usr/local/bin/perl -w
# MIME �᡼��� TypePad PhotoAlbum API �ǥݥ���

use strict;

# MIME �᡼���ѡ���
use MIME::Parser;

# Atom API ���åפ��� OO �⥸�塼��
use XML::Atom::Entry;
use XML::Atom::Client;
use XML::Atom;

# MIME B ���󥳡���/�ǥ�����
use Encode;
use Encode::MIME::Header;

# �����ѿ�
# $AtomAPI: Atom API �Υ���ɥݥ����
#   set_id �� Photo Album �� ID: �������̤� URL ����Ĵ�٤�
# $Username:    TypePad �Υ桼��̾
# $Password:  TypePad �Υѥ����
our $AtomAPI   = "http://www.typepad.com/t/atom/gallery/set_id=7033";
our $Username  = "melody";
our $Password  = "nelson";

# .qmail �ե�����Ȥ��Ƶ�ư
# �᡼����ʸ�ϥإå����ߤ� STDIN ��������Ǥ���
# MIME::Parser �� MIME ���Ǥ�ѡ�������������Ф�
my $parser = MIME::Parser->new();

# �ѡ���������å�������ƥ�ݥ��˽��Ϥ��ʤ�
$parser->output_to_core(1);

# MIME �ǥѡ������� Atom �˥ݥ���
# �㳰�򥭥�å������饨�顼��λ
eval {
    my $entity = $parser->parse(\*STDIN);
    post_to_atom($entity);
};
if ($@) {
    die "Error while posting: $@";
}

# MIME::Entity ������Ȥä� TypePad PhotoAlbum Atom API �˥ݥ���
sub post_to_atom {
    my $entity = shift;

    # MIME::Entity ���� Subject, �ƥ����ȥѡ��Ȥ�ź�ղ�������Ф�
    my $subject = decode_mime_header($entity, "Subject");
    my $text    = decode("iso-2022-jp", $entity->parts(0)->bodyhandle->as_string);
    my $image   = $entity->parts(1)->bodyhandle->as_string;

    # Atom API �Υ��󥿥ե������Ȥʤ� XML::Atom::Client
    my $api = XML::Atom::Client->new;

    # �桼��̾�ȥѥ���ɤ򥻥å�
    $api->username($Username);
    $api->password($Password);

    # Atom API �˥ݥ��Ȥ��� Entry ��¤�Τ���
    # $image �� XML::Atom �Ǽ�ưŪ�� Base64 ���󥳡��ɤ����
    my $entry = XML::Atom::Entry->new;
    $entry->content($image);
    $entry->content->type('image/jpeg');

    # Subject �� title, ��ʸ�� summary �˥��å�
    #XXX title, summary �� UTF-8 byte ʸ����ˤ��Ƥ���
    $entry->title($subject);
    $entry->summary($text);

    # ����ɥݥ���� $AtomAPI �� createEntry �᥽�åɤ� $entry ��ݥ���
    # �֤��ͤϥ���ȥ���Խ���Ԥʤ� URI
    my $EditAPI = $api->createEntry($AtomAPI, $entry)
        or die $api->errstr;
}

# MIME::Entity ������ꤷ���إå�����Ф�
# MIME B �ǥ����ɤ��� Unicode ʸ����Ȥ����֤�
sub decode_mime_header {
    my($entity, $header) = @_;
    my $value = $entity->head->get($header);

    # Encode::MIME::Header �����Ѥ��� B �ǥ�����
    my $data = decode("MIME-Header", $value);
    chomp($data);
    return $data;
}
