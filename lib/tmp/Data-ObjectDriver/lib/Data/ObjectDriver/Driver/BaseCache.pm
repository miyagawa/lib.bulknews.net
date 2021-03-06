# $Id: /saus/cpan/Data-ObjectDriver/trunk/lib/Data/ObjectDriver/Driver/BaseCache.pm 24796 2006-02-07T04:08:40.839977Z miyagawa  $

package Data::ObjectDriver::Driver::BaseCache;
use strict;
use base qw( Data::ObjectDriver Class::Accessor::Fast
             Class::Data::Inheritable );

use Carp ();

__PACKAGE__->mk_accessors(qw( cache fallback ));
__PACKAGE__->mk_classdata(qw( Disabled ));

sub init {
    my $driver = shift;
    $driver->SUPER::init(@_);
    my %param = @_;
    $driver->cache($param{cache})
        or Carp::croak("cache is required");
    $driver->fallback($param{fallback})
        or Carp::croak("fallback is required");
    $driver;
}

sub lookup {
    my $driver = shift;
    my($class, $id) = @_;
    return $driver->fallback->lookup($class, $id)
        if $driver->Disabled;
    my $key = $driver->cache_key($class, $id);
    my $obj = $driver->get_from_cache($key);
    unless ($obj) {
        $obj = $driver->fallback->lookup($class, $id);
        $driver->add_to_cache($key, $obj->clone_all) if $obj;
    }
    $obj;
}

sub lookup_multi {
    my $driver = shift;
    my($class, $ids) = @_;
    return $driver->fallback->lookup_multi($class, @$ids)
        if $driver->Disabled;
    ## Use driver->lookup to look up each object in the cache, and fallback
    ## to the backend driver if object isn't found in the cache.
    my @got;
    for my $id (@$ids) {
        push @got, $driver->lookup($class, $id);
    }
    \@got;
}

## We fallback by default
sub fetch_data { 
    my $driver = shift;
    my ($obj) = @_;
    return $driver->fallback->fetch_data($obj);
}

sub search {
    my $driver = shift;
    return $driver->fallback->search(@_)
        if $driver->Disabled;
    my($class, $terms, $args) = @_;

    ## Tell the fallback driver to fetch only the primary columns,
    ## then run the search using the fallback.
    my $old = $args->{fetchonly};
    $args->{fetchonly} = $class->primary_key_tuple; 
    ## Disable triggers for this load. We don't want the post_load trigger
    ## being called twice.
    $args->{no_triggers} = 1;
    my @objs = $driver->fallback->search($class, $terms, $args);

    ## Load all of the objects using a lookup_multi, which is fast from
    ## cache.
    my $objs = $driver->lookup_multi($class, [ map $_->primary_key, @objs ]);

    ## Now emulate the standard search behavior of returning an
    ## iterator in scalar context, and the full list in list context.
    if (wantarray) {
        return @$objs;
    } else {
        return sub { shift @$objs };
    }
}

sub update {
    my $driver = shift;
    my($obj) = @_;
    return $driver->fallback->update($obj)
        if $driver->Disabled;
    my $key = $driver->cache_key(ref($obj), $obj->primary_key);
    $driver->update_cache($key, $obj->clone_all);
    $driver->fallback->update($obj);
}

sub remove {
    my $driver = shift;
    my($obj) = @_;
    return $driver->fallback->remove($obj)
        if $driver->Disabled;
    $driver->remove_from_cache($driver->cache_key(ref($obj), $obj->primary_key));
    $driver->fallback->remove($obj);
}

sub cache_key {
    my $driver = shift;
    my($class, $id) = @_;
    join ':', $class, ref($id) eq 'ARRAY' ? @$id : $id;
}

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
    my $driver = $_[0];
    (my $meth = $AUTOLOAD) =~ s/.+:://;
    no strict 'refs';
    Carp::croak("Cannot call method '$meth' on object '$driver'")
        unless $driver->fallback->can($meth);
    *$AUTOLOAD = sub {
        shift->fallback->$meth(@_);
    };
    goto &$AUTOLOAD;
}

1;
