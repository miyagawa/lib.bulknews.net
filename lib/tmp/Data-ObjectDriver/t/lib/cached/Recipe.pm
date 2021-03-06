# $Id: /saus/cpan/Data-ObjectDriver/trunk/t/lib/cached/Recipe.pm 19907 2005-09-23T19:53:40.127273Z btrott  $

package Recipe;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Data::ObjectDriver::Driver::DBI;

__PACKAGE__->install_properties({
    columns => [ 'id', 'title' ],
    datasource => 'recipes',
    primary_key => 'id',
    driver => Data::ObjectDriver::Driver::DBI->new(
        dsn      => 'dbi:SQLite:dbname=global.db',
    ),
});

1;
