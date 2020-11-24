package MT::Plugin::TBPingDSBL;
# MT plugin to deny Trackback Pings from DSBLed IPs
# License: Same as Perl
# Author:  Tatsuhiko Miyagawa <miyagawa at bulknews.net>
#   Most of the code and idea stolen from Brad Choate's MT-DSBL
#   http://bradchoate.com/weblog/2004/11/05/mt-dsbl

use strict;
use MT;
use MT::Plugin;

our $VERSION = "0.90";

my $plugin = MT::Plugin->new({
    name => "TBPingDSBL v$VERSION",
    description => "Deny Trackback pings from DSBLed hosts",
});

MT->add_plugin($plugin);
#MT->add_callback('TBPingThrottleFilter', 2, $plugin, \&handler);
MT->add_callback('TBPingFilter', 2, $plugin, \&handler);

sub handler {
    my($eh, $app, $tb) = @_;
    my $ip = $app->remote_ip;
    my $dsbl_ip = join(".", reverse split /\./, $ip) . ".list.dsbl.org";
    if (checkdnsrr($dsbl_ip)) {
	$app->log("Blocked trackback pings from known open proxy: $ip");
	return 0;
    }
    return 1;
}

sub checkdnsrr {
    my ($ip, $type) = @_;
    if (eval 'require Net::DNS') {
	my $res = Net::DNS::Resolver->new;
	my $query = $res->search($ip);
	if ($query) {
	    foreach my $rr ($query->answer) {
		if ($type) {
		    next unless $rr->type eq $type;
		}
		return 1;
	    }
	}
    } else {
	my $opt = $type ? '-ty='.$type : '';
	my $out = `nslookup -sil $opt $ip`;
	if ($out && ($out !~ 'NXDOMAIN')) {
	    return 1;
	}
    }
    return 0;
}

1;
