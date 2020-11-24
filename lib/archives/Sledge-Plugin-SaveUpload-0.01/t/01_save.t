# $Id$
use strict;
use Test::More tests => 2;

package Mock::Pages;
use lib "t/lib";
use base qw(Sledge::TestPages);

use Sledge::Plugin::SaveUpload;

use vars qw($TMPL_PATH);
$TMPL_PATH = "t";

sub dispatch_upload {
    my $self = shift;
    my $upload  = $self->r->upload('file1');
    $upload->save("t/test");
    ::is -s "t/test", 8;
    unlink "t/test";
    die "Dummy";
}

package main;

use HTTP::Request::Common;
use FileHandle;

# simulates file upload
my $req = POST '/foo.cgi',
    Content_Type => 'form-data',
    Content => [
        name => 'miyagawa',
        file1 => [ 't/upload.txt' ],
    ];

my $post = $req->as_string;

$post =~ s/^POST.*\n//;
$post =~ s
    {^Content-Length: (\d+)\n}
    {$ENV{CONTENT_LENGTH} = $1; ""}e;
$post =~ s
    {^Content-Type: (.*)\n\n}
    {$ENV{CONTENT_TYPE} = $1; ""}e;

$ENV{REQUEST_METHOD} = 'POST';
$ENV{HTTP_USER_AGENT} = 'mozilla';

tie *STDIN, 'IO::Scalar', \$post;

my $p = Mock::Pages->new;
eval { $p->dispatch('upload'); };
like $@, qr/Dummy/;


