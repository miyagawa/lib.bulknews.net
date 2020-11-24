package Sledge::Plugin::SaveUpload;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use File::Copy;

sub import {
    my $class = shift;
    my $target_class = $ENV{MOD_PERL} ? 'Apache::Upload' : 'Sledge::Request::Upload';
    no strict 'refs';
    *{"$target_class\::save"} = sub {
	my($self, $path) = @_;
	link($self->tempname, $path) or copy($self->tempname, $path);
    };
}

1;
__END__

=head1 NAME

Sledge::Plugin::SaveUpload - Portable upload-E<gt>link()

=head1 SYNOPSIS

  package Your::Pages;
  use Sledge::Plugin::SaveUpload;

  my $upload = $self->r->upload('upload_file');
  $upload->save($local_path);

=head1 DESCRIPTION

Sledge::Plugin::SaveUpload �� Apache::Upload �⤷���� Sledge::Request::Upload �� C<link> ����ݡ����֥�����Ѥ��뤿���Sledge�ץ饰����Ǥ���C<link>�ؿ��ϡ�Cross device �Ǥ�ư��ʤ����ᡢC</tmp>����disk�ˤʤäƤ�����ʤɤ�ư��ޤ����н�ˡ�Ȥ��ƤϴĶ��ѿ� C<TMPDIR> �ʤɤ��Խ�������ˡ������ޤ��������Υץ饰����Ǥ�C<link>�˼��Ԥ�������C<copy>��¹Ԥ��ޤ���

=head1 AUTHOR

Original code by Satoshi Tanimoto E<lt>tanimoto@edge.co.jpE<gt>.

Code reimplemented by Tatsuhiko Miyagawa E<lt>miyagawa@edge.co.jpE<gt>

=head1 SEE ALSO

L<Apache::Request>, L<Sledge::Request::CGI>, L<File::Copy>

=cut
