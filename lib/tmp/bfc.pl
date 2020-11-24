#!/usr/bin/perl
use strict;
use vars qw/$VERSION/;
use Parse::RecDescent;

$VERSION = '0.01';
#$::RD_TRACE = 80;

sub CODE_INC () {<< 'EOC'}
    get_keyed I1, P0, I0
    inc I1
    and I1, I1, 0xFF
    set_keyed P0, I0, I1
EOC

sub CODE_DEC () {<< 'EOC'}
    get_keyed I1, P0, I0
    dec I1
    and I1, I1, 0xFF
    set_keyed P0, I0, I1
EOC

sub CODE_RIGHT () {<< 'EOC'}
    inc I0
EOC

sub CODE_LEFT () {<< 'EOC'}
    dec I0
EOC

sub CODE_IN () {<< 'EOC'}
    read S1, 1
    ord I1, S1
    set_keyed P0, I0, I1
EOC

sub CODE_OUT () {<< 'EOC'}
    get_keyed I1, P0, I0
    substr S1, S0, I1, 1
    print S1
EOC

{my $cnt = 0;
sub CODE_WBEGIN () {++$cnt ? << "EOC" : 0}
_W$cnt:
EOC

sub CODE_WEND () {<< "EOC"}}
    get_keyed I1, P0, I0
    substr S1, S0, I1, 1
    substr S2, S0, 0, 1
    ne S1, S2, _W$cnt
EOC

my $parser = Parse::RecDescent->new(<< 'EOG' );
    prog: exp(s) { $item[1] }
    exp:
	  '+' { 'CODE_INC' }
	| '-' { 'CODE_DEC' }
	| '>' { 'CODE_RIGHT' }
	| '<' { 'CODE_LEFT' }
	| ',' { 'CODE_IN' }
	| '.' { 'CODE_OUT' }
	| loop

    loop: '[' exp(s) ']'
	{ ['CODE_WBEGIN', @{$item[2]}, 'CODE_WEND'] }
EOG

print << 'EOC';
    new P0, PerlArray
    set I0, 0
    set S0, "\x0\x1\x2\x3\x4\x5\x6\x7\x8\x9\xa\xb\xc\xd\xe\xf\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff"
EOC

my $bf;
my $file = shift;
if( -e $file ) {
    open BF , $file or die "$!: $file";
    local $/ = undef;
    $bf = <BF>;

} else {
    $bf = $file;
}

my $ret = $parser->prog( $bf ) or die "couldn't compile";
_dump( $ret );

sub _dump {
    my $op = shift;

    if( 'ARRAY' eq ref $op ) {
	_dump( $_ ) for @$op;

    } else {
	no strict 'refs';
	print $op->();
    }
}
