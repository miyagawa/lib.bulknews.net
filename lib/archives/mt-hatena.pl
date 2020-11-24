package MT::Plugin::Hatena;

use strict;
use FileHandle;
use Jcode;
use LWP::UserAgent;
use URI::Escape;

our $VERSION = "1.00";

# �ϤƤʥ�����ɥꥹ�Ȥ� API
# ���������¸���륭��å���ե�����̾
our $url       = "http://d.hatena.ne.jp/images/keyword/keywordlist";
our $cachefile = "/mt/plugins/hatenacache/keywordlist";

# MT::Template::Context ���� global_filter ���ɲä���
use MT::Template::Context;
MT::Template::Context->add_global_filter(markup_hatena => \&markup_hatena);

# ����ɽ����ꥯ��������ǤϻȤ��󤹤���˥���å���
# mod_perl �ξ�祵���Хץ����������Ƥ���¤ꥭ��å���
my $regexp;

# ����ƥ����ʸ������Ȥꡢ�ϤƤʥ������꡼�Υ�����ɤ˥ޡ������å�
sub markup_hatena {
    my $content = shift;

    # ����ɽ������������
    # 2���ܰʹߤϥ���å��夫��
    $regexp ||= init_keyword_regexp();

    if ($regexp) {
	# ��ʸ�� euc-jp ���Ѵ����Ƥ���ޥå�������
	# ConfigMgr ���� PublishCharset ��������� Jcode �� euc-jp ��
	my $cfg = MT::ConfigMgr->instance;
	my $code = iana2jcode($cfg->PublishCharset);
	my $body = Jcode->new($content, $code)->euc;

	# ������ɤ˥ޥå������ơ��ϤƤʥ������꡼������ɤإ��
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

# �ϤƤʥ������꡼������ɤ�������ƥ���ѥ��뤷��Regexp���֥������Ȥ��֤�
sub init_keyword_regexp {
    # User-Agent: �� mt-hatena �ȥС���������򥻥å�
    my $ua  = LWP::UserAgent->new;
    $ua->agent("mt-hatena/$VERSION"); 

    # mirror �᥽�åɤǼ���: Conditional GET
    my $response = $ua->mirror($url => $cachefile);
    
    # ����å���ե����뤫������ɽ������
    if (my $fh = FileHandle->new($cachefile)) {
	my $pattern = do { local $/; <$fh> };
	return qr/$pattern/;
    } else {
	die "Error while getting Hatena Keyword: ", $response->code; 
    }
}

# "euc-jp" �Τ褦�� IANA Charset ̾���� Jcode �� $icode ��
# ���ѤǤ��륳����̾���Ѵ� �ǥե���Ȥ� UTF-8
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
