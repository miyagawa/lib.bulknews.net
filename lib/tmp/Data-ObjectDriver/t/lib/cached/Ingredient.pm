# $Id: /saus/cpan/Data-ObjectDriver/trunk/t/lib/cached/Ingredient.pm 19909 2005-09-23T20:13:56.018165Z btrott  $

package Ingredient;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Carp ();
use Data::ObjectDriver::Driver::DBI;
use Data::ObjectDriver::Driver::Cache::Cache;
use Cache::Memory;

our %IDs;

__PACKAGE__->install_properties({
    columns => [ 'id', 'recipe_id', 'name', 'quantity' ],
    datasource => 'ingredients',
    primary_key => [ 'recipe_id', 'id' ],
    driver      => Data::ObjectDriver::Driver::Cache::Cache->new(
        cache => Cache::Memory->new,
        fallback => Data::ObjectDriver::Driver::DBI->new(
            dsn      => 'dbi:SQLite:dbname=global.db',
            pk_generator => \&generate_pk,
        ),
        pk_generator => \&generate_pk,
    ),
});

sub generate_pk {
    my($obj) = @_;
    $obj->id(++$IDs{$obj->recipe_id});
    1;
}

1;
