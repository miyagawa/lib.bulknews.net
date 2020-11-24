package DBIx::GeneratedKey;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

sub new {
    my($class, $dbh) = @_;
    my $name = $dbh->{Driver}->{Name};
    my $module = "DBIx::GeneratedKey::$name";
    eval "require $module";
    if ($@) {
	require Carp;
	Carp::croak("driver $name is not supported.");
    }
    bless { dbh => $dbh }, $module;
}

sub get_generated_key { die "ABSTRACT" }

1;
__END__

=head1 NAME

DBIx::GeneratedKey - DBD portable last_insert_id

=head1 SYNOPSIS

  use DBIx::GeneratedKey;

  $id = DBIx::GeneratedKey->new($sth)->get_generated_key;

=head1 DESCRIPTION

DBIx::GeneratedKey provides you DBD portable way to get gennerated key
of last insert. Currently supported drivers are:

  mysql
  mysqlPP
  SQLite

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBI>

=cut
