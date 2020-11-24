package Class::DBI::View::TemporaryTable;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

sub setup_view {
    my($class, $sql) = @_;
    for my $method (qw(retrieve_all retrieve search search_like)) {
	_set_temporary_table($class, $method, $sql);
    }

}

sub _set_temporary_table {
    my($class, $method, $sql) = @_;
    no strict 'refs';
    *{"$class\::$method"} = sub {
	my $real_class = shift;
	my $temp_table = $real_class->_class_name . "_$$";
	my $create_sql = sprintf(
	    q/CREATE TEMPORARY TABLE IF NOT EXISTS %s %s/,
	    $temp_table, $sql,
	);
	$real_class->db_Main->do($create_sql);
	$real_class->table($temp_table);
	return $real_class->${\"Class::DBI::$method"}(@_);
    };
}

1;
__END__

=head1 NAME

Class::DBI::View::TemporaryTable - View implementation using temporary table

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

See L<Class::DBI::View>

=head1 NOTES

This module currently support only MySQL database.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI::View>

=cut
