# $Id: /saus/cpan/Data-ObjectDriver/trunk/t/lib/views/Ingredient2Recipe.pm 22931 2005-12-13T07:58:53.640647Z btrott  $

package Ingredient2Recipe;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Data::ObjectDriver::Driver::DBI;

__PACKAGE__->install_properties({
    columns => [ 'recipe_id', 'ingredient_id' ],
    datasource => 'ingredient2recipe',
    primary_key => [ 'recipe_id', 'ingredient_id', ],
    driver      => Data::ObjectDriver::Driver::DBI->new(
            dsn      => 'dbi:SQLite:dbname=global.db',
    ),
});

1;
