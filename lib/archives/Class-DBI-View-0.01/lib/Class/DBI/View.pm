package Class::DBI::View;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use UNIVERSAL::require;

sub _croak { require Carp; Carp::croak(@_) }

my %allowed = map { $_ => 1 } qw(TemporaryTable SubQuery Having);

sub import {
    my($class, $strategy) = @_;
    my $pkg = caller;

    defined $strategy   or _croak("You should supply strategy for setup_view()");
    $allowed{$strategy} or _croak("strategy $strategy is not implemented in Class::DBI::View");

    my $mod = "Class::DBI::View::$strategy";
       $mod->require or _croak($UNIVERSAL::require::ERROR);
    no strict 'refs';
    *{"$pkg\::setup_view"} = \&{"$mod\::setup_view"};
}

1;
__END__

=head1 NAME

Class::DBI::View - Virtual table for Class::DBI

=head1 SYNOPSIS

  package CD::Music::SalesRanking;
  use base qw(CD::DBI); # your Class::DBI base class
  use Class::DBI::View qw(TemporaryTable);

  __PACKAGE__->columns(All => qw(id count));
  __PACKAGE__->setup_view(<<SQL);
    SELECT cd_id AS id, COUNT(*) AS count
    FROM cd_sales
    GROUP BY cd_id
    ORDER BY count
    LIMIT 1, 10
  SQL


=head1 DESCRIPTION

Class::DBI::View is a Class::DBI wrapper to make virtual VIEWs.

=head1 METHODS

=over 4

=item import

  use Class::DBI::View qw(TemporaryTable);
  use Class::DBI::View qw(SubQuery);
  use Class::DBI::View qw(Having);

When use()ing this module, you should supply which strategy
(implmentation) you use to create virtual view, which is one of
'TemporaryTable', 'SubQuery' or 'Having'.

=item setup_view

  $class->setup_view($sql);

Setups virtual VIEWs for C<$class>. C<$sql> should be raw SQL statement
to build a VIEW.

=back

=head1 NOTES

Currently update/delete/insert-related methods (like C<create>) are
not supported. Supporting it would make things too complicated. Only
SELECT-related methods (C<search> etc.) would be enough. (Patches
welcome, off course)

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>

=cut
