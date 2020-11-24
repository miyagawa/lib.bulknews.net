package DBIx::GeneratedKey::SQLite;
use strict;
use base qw(DBIx::GeneratedKey);

sub get_generated_key {
    my $self = shift;
    return $self->{dbh}->func('last_insert_rowid');
}

1;

