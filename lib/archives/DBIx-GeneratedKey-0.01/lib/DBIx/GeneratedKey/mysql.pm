package DBIx::GeneratedKey::mysql;
use strict;
use base qw(DBIx::GeneratedKey);

sub get_generated_key {
    my $self = shift;
    return $self->{dbh}->{mysql_insertid};
}

1;
