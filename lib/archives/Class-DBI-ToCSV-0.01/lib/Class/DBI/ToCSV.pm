package Class::DBI::ToCSV;

use strict;
use vars qw($VERSION @EXPORT);
$VERSION = 0.01;

require Exporter;
*import = \&Exporter::import;
@EXPORT = qw(to_csv);

use Text::CSV_XS;

use vars qw($LineFeed);
$LineFeed = "\n";

sub to_csv {
    my $proto = shift;
    return ref $proto ? _object_to_csv($proto, @_) : _class_to_csv($proto, @_);
}

sub _object_to_csv {
    my($self, $group, $fh) = @_;
    my $csv = Text::CSV_XS->new({ binary => 1 });
    my @col = map $self->get($_), $self->columns($group);
    $csv->combine(@col);
    print $fh $csv->string(), $LineFeed;
}

sub _class_to_csv {
    my($class, $group, $fh, $args) = @_;
    my $iter = defined $args && ref($args) eq 'HASH' ?
	$class->search(%$args) : $class->retrieve_all;
    while (my $obj = $iter->next) {
	$obj->to_csv($group, $fh);
    }
}

1;
__END__

=head1 NAME

Class::DBI::ToCSV - Class::DBI utility for CSV generation

=head1 SYNOPSIS

  package CD::Music;
  use base qw(Class::DBI);
  use Class::DBI::ToCSV;
  __PACKAGE__->columns(ForCSV => qw(id title artist label release_date));

  package main;

  # object method
  my $iter = CD::Music->search_like(artist => 'Ozzy %');
  while (my $music = $iter->next) {
      $music->to_csv(ForCSV => \*STDOUT);
  }

  # class method: do it all in one call
  CD::Music->to_csv(All => \*STDOUT);

  # or, you can add search args in hash-ref
  CD::Music->to_csv(All => \*STDOUT, { artist => 'Kelly Osbourne' });

=head1 DESCRIPTION

Class::DBI::ToCSV is a Class::DBI plugin to glue Text::CSV_XS into
your data class. It'll reduce your tedious work to output CSV records
from your database objects.

=head1 METHODS

Use()ing this module in your data class brings following methods into
your namespace.

=over 4

=item to_csv

  $obj->to_csv($col_group, $fh);
  $class->to_csv($col_group, $fh, \%search_args);

You can use to_csv() methods as either object method or class method.
C<$col_group> is a name of a column group defined in your
class. C<$fh> is a filehandle to print CSV record on.

You can pass additional parameter to pass to C<search>, when you use
this as a class method. If you want more flexibility on how to select
objects rather than simple C<search>, you should consider using it as
an object method, like:

  package CD::Music;
  use Class::DBI::AbstractSearch;
  use Class::DBI::ToCSV;

  package main;
  my $iter = CD::Music->search_where(artist => [ qw(Ozzy Kelly) ]);
  while (my $music = $iter->next) {
      $music->to_csv(All => $fh);
  }

You can omit C<%search_args>, then it'll invoke C<retrieve_all>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Text::CSV_XS>

=cut
