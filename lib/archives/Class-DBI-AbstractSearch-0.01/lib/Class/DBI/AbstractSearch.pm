package Class::DBI::AbstractSearch;

use strict;
use vars qw($VERSION @EXPORT);
$VERSION = 0.01;

require Exporter;
*import = \&Exporter::import;
@EXPORT = qw(search_where);

use SQL::Abstract;

sub search_where {
    my($class, %where) = @_;
    $class->can('retrieve_from_sql') or do {
	require Carp;
	Carp::croak("$class should inherit from Class::DBI >= 0.90");
    };
    my $sql = SQL::Abstract->new; # XXX how do we supply options here?
    my($where, @bind) = $sql->where(\%where);
    $where =~ s/^\s*WHERE\s*//i;
    return $class->retrieve_from_sql($where, @bind);
}

1;
__END__

=head1 NAME

Class::DBI::AbstractSearch - Abstract Class::DBI's SQL with SQL::Abstract

=head1 SYNOPSIS

  package CD::Music;
  use Class::DBI::AbstractSearch;

  pacage main;
  my @music = CD::Music->search_where(
      artist => [ 'Ozzy', 'Kelly' ],
      status => { '!=', 'outdated' },
  );

=head1 DESCRIPTION

Class::DBI::AbstractSearch is a Class::DBI plugin to glue
SQL::Abstract into Class::DBI.

=head1 METHODS

Using this module adds following methods into your data class.

=over 4

=item search_where

  $class->search_where(%where);

takes hash to specify WHERE clause. See L<SQL::Abstract> for hash
options.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt> with some help from
cdbi-talk maling list, especially:

  Tim Bunce
  Simon Wilcox
  Tony Bowden

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<SQL::Abstract>

=cut
