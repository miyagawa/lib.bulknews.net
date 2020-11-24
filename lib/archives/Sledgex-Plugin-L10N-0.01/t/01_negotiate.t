use strict;
use Test::More 'no_plan';

use lib '../../t/lib';

package Mock::Pages;
use base qw(Sledge::TestPages);

use vars qw($TMPL_PATH);
$TMPL_PATH = 't/view';

use Sledgex::Plugin::L10N;

__PACKAGE__->languages({
    ja => { charset => 'euc-jp', quality => 1.0, }, # ja is default. so q=1.0
    en => { charset => 'us-ascii' },
    de => { charset => 'iso-8859-1' },
});

sub create_charset {
    my $self = shift;
    return Sledgex::Charset::L10N->new($self);
}

sub dispatch_foo { }
sub dispatch_bar { }

package main;

my @Tests = (
    # accept, regexes
    [ 'en', qr/charset=us-ascii/, qr/hello English world/ ],
    [ 'ja', qr/charset=euc-jp/, qr/hello Japanese world/ ],
    [ 'de', qr/hello Japanese world/ ],	# no .de.html file, should be default .ja
    [ 'ja,en;q=0.5', qr/charset=euc-jp/, qr/hello Japanese world/ ],
    [ undef, qr/charset=euc-jp/, qr/hello Japanese world/ ], # no HTTP_ACCEPT_LANGUAGE
);

for (@Tests) {
    my($accept, @regexes) = @$_;

    # test foo
    local $ENV{HTTP_ACCEPT_LANGUAGE} = $accept if $accept;
    my $p = Mock::Pages->new;
    $p->dispatch('foo');

    for my $re (@regexes) {
	like $p->output, $re, $accept || 'default';
    }

    # test bar
    $p = Mock::Pages->new;
    $p->dispatch('bar');

    # no L10N files for bar: so bar.html
    like $p->output, qr/Hello default world: bar/;
}

