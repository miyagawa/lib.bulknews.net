# $Id: /saus/cpan/Data-ObjectDriver/trunk/lib/Data/ObjectDriver/Driver/DBD/Pg.pm 24588 2006-01-10T22:22:10.413317Z mpaschal  $

package Data::ObjectDriver::Driver::DBD::Pg;
use strict;
use base qw( Data::ObjectDriver::Driver::DBD );

sub init_dbh {
    my $dbd = shift;
    my($dbh) = @_;
    $dbh->do("set timezone to 'UTC'");
    $dbh;
}

sub bind_param_attributes {
    my ($dbd, $data_type) = @_;
    if ($data_type && $data_type eq 'blob') {
        return { pg_type => DBD::Pg::PG_BYTEA() };
    }
    return undef;
}

sub sequence_name {
    my $dbd = shift;
    my($class) = @_;
    join '_', $class->datasource,
        $dbd->db_column_name($class->datasource, $class->properties->{primary_key}),
        'seq';
}

sub fetch_id {
    my $dbd = shift;
    my($class, $dbh, $sth) = @_;
    $dbh->last_insert_id(undef, undef, undef, undef,
        { sequence => $dbd->sequence_name($class) });
}

1;
