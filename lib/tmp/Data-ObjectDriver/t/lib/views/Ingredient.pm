# $Id: /saus/cpan/Data-ObjectDriver/trunk/t/lib/views/Ingredient.pm 22931 2005-12-13T07:58:53.640647Z btrott  $

package Ingredient;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Data::ObjectDriver::Driver::DBI;

our $ID = 0;

__PACKAGE__->install_properties({
    columns => [ 'id', 'name', 'quantity' ],
    datasource => 'ingredients',
    primary_key => 'id',
    driver      => Data::ObjectDriver::Driver::DBI->new(
            dsn      => 'dbi:SQLite:dbname=global.db',
            pk_generator => \&generate_pk,
    ),
});

sub generate_pk {
    my($obj) = @_;
    $obj->id(++$ID);
    1;
}

1;
