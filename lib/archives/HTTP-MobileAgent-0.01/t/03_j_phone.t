use strict;
use Test::More tests => 163;

BEGIN { use_ok 'HTTP::MobileAgent' }

my @Tests = (
    # ua, version, model, packet_compliant, serial_number, vendor, vendor_version, java_infos
    [ 'J-PHONE/2.0/J-DN02', '2.0', 'J-DN02', undef ],
    [ 'J-PHONE/3.0/J-PE03_a', '3.0', 'J-PE03_a', undef ],
    [ 'J-PHONE/4.0/J-SH51/SNJSHA3029293 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0',
      '4.0', 'J-SH51', 1, 'JSHA3029293', 'SH', '0001aa', {
	  Profile =>'MIDP-1.0',
	  Configuration => 'CLDC-1.0',
	  'Ext-Profile' => 'JSCL-1.1.0',
      } ],
    [ 'J-PHONE/4.0/J-SH51/SNXXXXXXXXX SH/0001a Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0',
      '4.0', 'J-SH51', 1, 'XXXXXXXXX', 'SH', '0001a', {
	  Profile => 'MIDP-1.0',
	  Configuration => 'CLDC-1.0',
	  'Ext-Profile' => 'JSCL-1.1.0',
      }],
);

for (@Tests) {
    my($ua, @data) = @$_;
    my $agent = HTTP::MobileAgent->new($ua);
    isa_ok $agent, 'HTTP::MobileAgent';
    isa_ok $agent, 'HTTP::MobileAgent::JPhone';
    ok $agent->is_j_phone;
    is $agent->name, 'J-PHONE';
    is $agent->user_agent, $ua,		"ua is $ua";

    is $agent->version, $data[0],	"version is $data[0]";
    is $agent->model, $data[1],		"model is $data[1]";
    is $agent->packet_compliant, $data[2], "packet compliant?";
    if (@data > 3) {
	is $agent->serial_number, $data[3],	"serial is $data[3]";
	is $agent->vendor, $data[4],		"vendor is $data[4]";
	is $agent->vendor_version, $data[5],	"vendor version is $data[5]";
	is_deeply $agent->java_info, $data[6];
    }
}

while (<DATA>) {
    next if /^#/;
    chomp;
    local $ENV{HTTP_USER_AGENT} = $_;
    my $agent = HTTP::MobileAgent->new;
    isa_ok $agent, 'HTTP::MobileAgent', "$_";
    is $agent->name, 'J-PHONE';
}

__END__
J-PHONE/1.0
J-PHONE/2.0/J-DN02
J-PHONE/2.0/J-P02
J-PHONE/2.0/J-P03
J-PHONE/2.0/J-SA02
J-PHONE/2.0/J-SH02
J-PHONE/2.0/J-SH03
J-PHONE/2.0/J-SH03_a
J-PHONE/2.0/J-SH04
J-PHONE/2.0/J-T04
J-PHONE/2.0/J-T05
J-PHONE/3.0/J-D03
J-PHONE/3.0/J-D04
J-PHONE/3.0/J-D05
J-PHONE/3.0/J-DN03
J-PHONE/3.0/J-K03
J-PHONE/3.0/J-K04
J-PHONE/3.0/J-K05
J-PHONE/3.0/J-N03
J-PHONE/3.0/J-N03B
J-PHONE/3.0/J-N04
J-PHONE/3.0/J-N05
J-PHONE/3.0/J-NM01_a
J-PHONE/3.0/J-NM02
J-PHONE/3.0/J-PE03
J-PHONE/3.0/J-PE03_a
J-PHONE/3.0/J-SA03_a
J-PHONE/3.0/J-SA04
J-PHONE/3.0/J-SA04_a
J-PHONE/3.0/J-SH04
J-PHONE/3.0/J-SH04_a
J-PHONE/3.0/J-SH04_b
J-PHONE/3.0/J-SH04_c
J-PHONE/3.0/J-SH05
J-PHONE/3.0/J-SH05_a
J-PHONE/3.0/J-SH06
J-PHONE/3.0/J-SH07
J-PHONE/3.0/J-SH08
J-PHONE/3.0/J-T05
J-PHONE/3.0/J-T06
J-PHONE/3.0/J-T06_a
J-PHONE/3.0/J-T07
J-PHONE/4.0/J-K51/SNJKWA3001061 KW/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-K51/SNJKWA3040744 KW/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-P51/SNJMAA1036146 MA/JDP51A36 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA1032366 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA1041639 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA2901949 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA3008160 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA3016183 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA3029293 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNXXXXXXXXX SH/0001a Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA1045575 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA1082487 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA1086956 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA3093881 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA5081372 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-T51/SNJTSA1077171 TS/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-T51/SNJTSA1082745 TS/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-T51/SNJTSA3001961 TS/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
