# $Id: /saus/cpan/Data-ObjectDriver/trunk/lib/Data/ObjectDriver/Driver/DBD/mysql.pm 15774 2005-08-01T07:33:09.399006Z btrott  $

package Data::ObjectDriver::Driver::DBD::mysql;
use strict;
use base qw( Data::ObjectDriver::Driver::DBD );

use Carp qw( croak );

sub fetch_id { $_[3]->{mysql_insertid} || $_[3]->{insertid} }

1;
