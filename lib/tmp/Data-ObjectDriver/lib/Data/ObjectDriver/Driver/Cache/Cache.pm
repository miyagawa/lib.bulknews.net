# $Id: /saus/cpan/Data-ObjectDriver/trunk/lib/Data/ObjectDriver/Driver/Cache/Cache.pm 13988 2005-06-24T21:08:30.072776Z btrott  $

package Data::ObjectDriver::Driver::Cache::Cache;
use strict;
use base qw( Data::ObjectDriver::Driver::BaseCache );

sub get_from_cache    { shift->cache->thaw(@_)   }
sub add_to_cache      { shift->cache->freeze(@_) }
sub update_cache      { shift->cache->freeze(@_) }
sub remove_from_cache { shift->cache->remove(@_) }

1;
