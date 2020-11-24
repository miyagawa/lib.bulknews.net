package My::DB;

use strict;
use 5.004;

use DBI;

use vars qw(%c);
use constant DEBUG => 0;

%c =
  (
   db => {
	  DB_NAME      => 'foo',
	  SERVER       => 'localhost',
	  USER         => 'put_username_here',
	  USER_PASSWD  => 'put_passwd_here',
	 },

  );

use Carp qw(croak verbose);
#local $SIG{__WARN__} = \&Carp::cluck;

# untaint the path by explicit setting
local $ENV{PATH} = '/bin:/usr/bin';

#######
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};

    # connect to the DB, Apache::DBI takes care of caching the connections
    # save into a dbh - Database handle object
  $self->{dbh} = DBI->connect("DBI:mysql:$c{db}{DB_NAME}::$c{db}{SERVER}",
			       $c{db}{USER},
			       $c{db}{USER_PASSWD},
			       {
				PrintError => 1, # warn() on errors
				RaiseError => 0, # don't die on error
				AutoCommit => 1, # commit executes immediately
			       }
			      )
    or die "Cannot connect to database: $DBI::errstr";

    # we want to die on errors if in debug mode
  $self->{dbh}->{RaiseError} = 1 if DEBUG;

    # init the sth - Statement handle object
  $self->{sth} = '';

  bless ($self, $class);

  $self;

} # end of sub new



######################################################################
               ###################################
               ###                             ###
               ###       SQL Functions         ###
               ###                             ###
               ###################################
######################################################################

# print debug messages
sub d{
   # we want to print the trace in debug mode
  print "<DT><B>".join("<BR>", @_)."</B>\n" if DEBUG;

} # end of sub d


######################################################################
# return a count of matched rows, by conditions 
#
#  $count = sql_count_matched($table_name,\@conditions,\@restrictions);
#
# conditions must be an array so we can pass more than one column with
# the same name.
#
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                );
#
# The sub knows automatically to detect and quote strings
#
# Restrictions are the list of restrictions like ('order by email')
#
##########################
sub sql_count_matched{
  my $self    = shift;
  my $table   = shift || '';
  my $r_conds = shift || [];
  my $r_restr = shift || [];

    # we want to print the trace in debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "SELECT COUNT(*) FROM $table ";
  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {
    push @where, join " ",
      $$r_conds[$i],
      $$r_conds[$i+1][0],
      sql_quote(sql_escape($$r_conds[$i+1][1]));
  }
    # Add the where clause if we have one
  $do_sql .= "WHERE ". join " AND ", @where if @where;

    # restrictions (DONT put commas!)
  $do_sql .= " ". join " ", @{$r_restr} if @{$r_restr};

  d("SQL: $do_sql") if DEBUG;

    # do query
  $self->{sth} = $self->{dbh}->prepare($do_sql);
  $self->{sth}->execute();
  my ($count) = $self->{sth}->fetchrow_array;

  d("Result: $count") if DEBUG;

  $self->{sth}->finish;

  return $count;

} # end of sub sql_count_matched


######################################################################
# return a count of matched distinct rows, by conditions 
#
#  $count = sql_count_matched_distinct($table_name,\@conditions,\@restrictions);
#
# conditions must be an array so we can path more than one column with
# the same name.
#
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                );
#
# The sub knows automatically to detect and quote strings
#
# Restrictions are the list of restrictions like ('order by email')
#
# This a slow implementation - because it cannot use select(*), but
# brings all the records in first and then counts them. In the next
# version of mysql there will be an operator 'select (distinct *)'
# which will make things much faster, so we will just change the
# internals of this sub, without changing the code itself.
#
##############################
sub sql_count_matched_distinct{
  my $self    = shift;
  my $table   = shift || '';
  my $r_conds = shift || [];
  my $r_restr = shift || [];

    # we want to print the trace in debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "SELECT DISTINCT * FROM $table ";
  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {
    push @where, join " ",
      $$r_conds[$i],
      $$r_conds[$i+1][0],
      sql_quote(sql_escape($$r_conds[$i+1][1]));
  }
    # Add the where clause if we have one
  $do_sql .= "WHERE ". join " AND ", @where if @where;

    # restrictions (DONT put commas!)
  $do_sql .= " ". join " ", @{$r_restr} if @{$r_restr};

  d("SQL: $do_sql") if DEBUG;

    # do query
#  $self->{sth} = $self->{dbh}->prepare($do_sql);
#  $self->{sth}->execute();

  my $count = @{$self->{dbh}->selectall_arrayref($do_sql)};

#  my ($count) = $self->{sth}->fetchrow_array;

  d("Result: $count") if DEBUG;

#  $self->{sth}->finish;

  return $count;

} # end of sub sql_count_matched_distinct



######################################################################
# return a single (first) matched value or undef, by conditions and
# restrictions
#
# sql_get_matched_value($table_name,$column,\@conditions,\@restrictions);
#
# column is a name of the column
#
# conditions must be an array so we can path more than one column with
# the same name.
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                );
# The sub knows automatically to detect and quote strings
#
# restrictions is a list of restrictions like ('order by email')
#
##########################
sub sql_get_matched_value{
  my $self    = shift;
  my $table   = shift || '';
  my $column  = shift || '';
  my $r_conds = shift || [];
  my $r_restr = shift || [];

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "SELECT $column FROM $table ";

  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {
    push @where, join " ",
      $$r_conds[$i],
      $$r_conds[$i+1][0],
      sql_quote(sql_escape($$r_conds[$i+1][1]));
  }
    # Add the where clause if we have one
  $do_sql .= " WHERE ". join " AND ", @where if @where;

    # restrictions (DONT put commas!)
  $do_sql .= " ". join " ", @{$r_restr} if @{$r_restr};

  d("SQL: $do_sql") if DEBUG;

    # do query
  return $self->{dbh}->selectrow_array($do_sql);

} # end of sub sql_get_matched_value




######################################################################
# return a single row of first matched rows, by conditions and
# restrictions. The row is being inserted into @results_row array
# (value1,value2,...)  or empty () if none matched
#
# sql_get_matched_row(\@results_row,$table_name,\@columns,\@conditions,\@restrictions);
#
# columns is a list of columns to be returned (username, fname,...)
#
# conditions must be an array so we can path more than one column with
# the same name.
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                );
# The sub knows automatically to detect and quote strings
#
# restrictions is a list of restrictions like ('order by email')
#
##########################
sub sql_get_matched_row{
  my $self    = shift;
  my $r_row   = shift || {};
  my $table   = shift || '';
  my $r_cols  = shift || [];
  my $r_conds = shift || [];
  my $r_restr = shift || [];

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "SELECT ";
  $do_sql .= join ",", @{$r_cols} if @{$r_cols};
  $do_sql .= " FROM $table ";

  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {
    push @where, join " ",
      $$r_conds[$i],
      $$r_conds[$i+1][0],
      sql_quote(sql_escape($$r_conds[$i+1][1]));
  }
    # Add the where clause if we have one
  $do_sql .= " WHERE ". join " AND ", @where if @where;

    # restrictions (DONT put commas!)
  $do_sql .= " ". join " ", @{$r_restr} if @{$r_restr};

  d("SQL: $do_sql") if DEBUG;

    # do query
  @{$r_row} = $self->{dbh}->selectrow_array($do_sql);

} # end of sub sql_get_matched_row



######################################################################
# return a ref to hash of single matched row, by conditions
# and restrictions. return undef if nothing matched.
# (column1 => value1, column2 => value2) or empty () if non matched
#
# sql_get_hash_ref($table_name,\@columns,\@conditions,\@restrictions);
#
# columns is a list of columns to be returned (username, fname,...)
#
# conditions must be an array so we can path more than one column with
# the same name.
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                );
# The sub knows automatically to detect and quote strings
#
# restrictions is a list of restrictions like ('order by email')
#
##########################
sub sql_get_hash_ref{
  my $self    = shift;
  my $table   = shift || '';
  my $r_cols  = shift || [];
  my $r_conds = shift || [];
  my $r_restr = shift || [];

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "SELECT ";
  $do_sql .= join ",", @{$r_cols} if @{$r_cols};
  $do_sql .= " FROM $table ";

  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {
    push @where, join " ",
      $$r_conds[$i],
      $$r_conds[$i+1][0],
      sql_quote(sql_escape($$r_conds[$i+1][1]));
  }
    # Add the where clause if we have one
  $do_sql .= " WHERE ". join " AND ", @where if @where;

    # restrictions (DONT put commas!)
  $do_sql .= " ". join " ", @{$r_restr} if @{$r_restr};

  d("SQL: $do_sql") if DEBUG;

    # do query
  $self->{sth} = $self->{dbh}->prepare($do_sql);
  $self->{sth}->execute();

  return $self->{sth}->fetchrow_hashref;

} # end of sub sql_get_hash_ref





######################################################################
# returns a reference to an array, matched by conditions and
# restrictions, which contains one reference to array per row. If
# there are no rows to return, returns a reference to an empty array:
# [
#  [array1],
#   ......
#  [arrayN],
# ];
#
# $ref = sql_get_matched_rows_ary_ref($table_name,\@columns,\@conditions,\@restrictions);
#
# columns is a list of columns to be returned (username, fname,...)
#
# conditions must be an array so we can path more than one column with
# the same name. @conditions are being cancatenated with AND
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                );
# results in
# WHERE foo > 15 AND foo < 30
#
#  to make an OR logic use (then ANDed )
#  @conditions =  ( column => ['comp_sign',['value1','value2']],
#                  foo    => ['=',[15,24] ],
#                  bar    => ['=',[16,21] ],
#                );
# results in
# WHERE (foo = 15 OR foo = 24) AND (bar = 16 OR bar = 21)
#
# The sub knows automatically to detect and quote strings
#
# restrictions is a list of restrictions like ('order by email')
#
##########################
sub sql_get_matched_rows_ary_ref{
  my $self    = shift;
  my $table   = shift || '';
  my $r_cols  = shift || [];
  my $r_conds = shift || [];
  my $r_restr = shift || [];

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "SELECT ";
  $do_sql .= join ",", @{$r_cols} if @{$r_cols};
  $do_sql .= " FROM $table ";

  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {

    if (ref $$r_conds[$i+1][1] eq 'ARRAY') {
        # multi condition for the same field/comparator to be ORed
      push @where, map {"($_)"} join " OR ",
	map { join " ", 
		$r_conds->[$i],
		$r_conds->[$i+1][0],
		sql_quote(sql_escape($_));
	    } @{$r_conds->[$i+1][1]};
    } else {
        # single condition for the same field/comparator
      push @where, join " ",
	$r_conds->[$i],
        $r_conds->[$i+1][0],
        sql_quote(sql_escape($r_conds->[$i+1][1]));
    }
  } # end of for(my $i=0;$i<@{$r_conds};$i=$i+2

    # Add the where clause if we have one
  $do_sql .= " WHERE ". join " AND ", @where if @where;

    # restrictions (DONT put commas!)
  $do_sql .= " ". join " ", @{$r_restr} if @{$r_restr};

  d("SQL: $do_sql") if DEBUG;

    # do query
  return $self->{dbh}->selectall_arrayref($do_sql);

} # end of sub sql_get_matched_rows_ary_ref




######################################################################
# insert a single row into a DB
#
#  sql_insert_row($table_name,\%data,$delayed);
#
# data is hash of type (column1 => value1 ,column2 => value2 , )
#
# $delayed: 1 => do delayed insert, 0 or none passed => immediate
#
# * The sub knows automatically to detect and quote strings 
#
# * The insert id delayed, so the user will not wait untill the insert
# will be completed, if many select queries are running 
#
##########################
sub sql_insert_row{
  my $self    = shift;
  my $table   = shift || '';
  my $r_data = shift || {};
  my $delayed = (shift) ? 'DELAYED' : '';

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "INSERT $delayed INTO $table ";
  $do_sql   .= "(".join(",",keys %{$r_data}).")";
  $do_sql   .= " VALUES (";
  $do_sql   .= join ",", sql_quote(sql_escape( values %{$r_data} ) );
  $do_sql   .= ")";

  d("SQL: $do_sql") if DEBUG;

    # do query
  $self->{sth} = $self->{dbh}->prepare($do_sql);
  $self->{sth}->execute();

} # end of sub sql_insert_row


######################################################################
# update rows in a DB by condition
#
#  sql_update_rows($table_name,\%data,\@conditions,$delayed);
#
# data is hash of type (column1 => value1 ,column2 => value2 , )
#
# conditions must be an array so we can path more than one column with
# the same name.
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                ); 
#
# $delayed: 1 => do delayed insert, 0 or none passed => immediate
#
# * The sub knows automatically to detect and quote strings 
#
#
##########################
sub sql_update_rows{
  my $self    = shift;
  my $table   = shift || '';
  my $r_data = shift || {};
  my $r_conds = shift || [];
  my $delayed = (shift) ? 'LOW_PRIORITY' : '';

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "UPDATE $delayed $table SET ";
  $do_sql   .= join ",", 
    map { "$_=".join "",sql_quote(sql_escape($$r_data{$_})) } keys %{$r_data};

  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {
    push @where, join " ",
      $$r_conds[$i],
      $$r_conds[$i+1][0],
      sql_quote(sql_escape($$r_conds[$i+1][1]));
  }
    # Add the where clause if we have one
  $do_sql .= " WHERE ". join " AND ", @where if @where;


  d("SQL: $do_sql") if DEBUG;

    # do query
  $self->{sth} = $self->{dbh}->prepare($do_sql);

  $self->{sth}->execute();

#  my ($count) = $self->{sth}->fetchrow_array;
#
#  d("Result: $count") if DEBUG;

} # end of sub sql_update_rows


######################################################################
# delete rows from DB by condition
#
# sql_delete_rows($table_name,\@conditions);
#
# conditions must be an array so we can path more than one column with
# the same name.
#  @conditions =  ( column => ['comp_sign','value'],
#                  foo    => ['>',15],
#                  foo    => ['<',30],
#                );
#
# * The sub knows automatically to detect and quote strings 
#
#
##########################
sub sql_delete_rows{
  my $self    = shift;
  my $table   = shift || '';
  my $r_conds = shift || [];

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

    # build the query
  my $do_sql = "DELETE FROM $table ";

  my @where = ();
  for(my $i=0;$i<@{$r_conds};$i=$i+2) {
    push @where, join " ",
      $$r_conds[$i],
      $$r_conds[$i+1][0],
      sql_quote(sql_escape($$r_conds[$i+1][1]));
  }

    # Must be very careful with deletes, imagine somehow @where is
    # not getting set, "DELETE FROM NAME" deletes the contents of the table
  warn("Attempt to delete a whole table $table from DB\n!!!"),return unless @where;

    # Add the where clause if we have one
  $do_sql .= " WHERE ". join " AND ", @where;

  d("SQL: $do_sql") if DEBUG;

    # do query
  $self->{sth} = $self->{dbh}->prepare($do_sql);
  $self->{sth}->execute();

} # end of sub sql_delete_rows


######################################################################
# executes the passed query and returns a reference to an array which
# contains one reference per row. If there are no rows to return,
# returns a reference to an empty array.
#
# $r_array = sql_execute_and_get_r_array($query);
#
#
##########################
sub sql_execute_and_get_r_array{
  my $self     = shift;
  my $do_sql   = shift || '';

    # we want to print in the trace debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

  d("SQL: $do_sql") if DEBUG;

  $self->{dbh}->selectall_arrayref($do_sql);

} # end of sub sql_execute_and_get_r_array


######################################################################
# lock the passed tables in the requested mode (READ|WRITE) and set
# internal flag to handle possible user abortions, so the tables will
# be unlocked thru the END{} block
#
# sql_lock_tables('table1','lockmode',..,'tableN','lockmode'
# lockmode = (READ | WRITE)
#
# _side_effect_ $self->{lock} = 'On';
#
##########################
sub sql_lock_tables{
  my $self   = shift;
  my %modes = @_;

  return unless %modes;

  my $do_sql = 'LOCK TABLES ';
  $do_sql .= join ",", map {"$_ $modes{$_}"} keys %modes;

    # we want to print the trace in debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

  d("SQL: $do_sql") if DEBUG;

  $self->{sth} = $self->{dbh}->prepare($do_sql);
  $self->{sth}->execute();

    # Enough to set only one lock, unlock will remove them all
  $self->{lock} = 'On';

} # end of sub sql_lock_tables



######################################################################
# unlock all tables, unset internal flag to handle possible user
# abortions, so the tables will be unlocked thru the END{} block
#
# sql_unlock_tables()
#
# _side_effect_: delete $self->{lock}
#
##########################
sub sql_unlock_tables{
  my $self   = shift;

    # we want to print the trace in debug mode
  d( "[".(caller(2))[3]." - ".(caller(1))[3]." - ". (caller(0))[3]."]") if DEBUG;

  $self->{dbh}->do("UNLOCK TABLES");

    # Enough to set only one lock, unlock will remove them all
  delete $self->{lock};

} # end of sub sql_unlock_tables

#
#
# return current date formatted for a DATE field type
# YYYYMMDD
#
# Note: since this function actually doesn't need an object it's being
# called without parameter as well as procedural call
############
sub sql_date{
  my $self     = shift;

  my ($mday,$mon,$year) = (localtime)[3..5];
  return sprintf "%0.4d%0.2d%0.2d",1900+$year,++$mon,$mday;

} # end of sub sql_date

#
#
# return current date formatted for a DATE field type
# YYYYMMDDHHMMSS
#
# Note: since this function actually doesn't need an object it's being
# called without parameter as well as procedural call
############
sub sql_datetime{
  my $self     = shift;

  my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
  return sprintf "%0.4d%0.2d%0.2d%0.2d%0.2d%0.2d",1900+$year,++$mon,$mday,$hour,$min,$sec;

} # end of sub sql_datetime


# Quote the list of parameters.  Parameters consisting entirely of
# digits (i.e. integers) are unquoted.
# print sql_quote("one",2,"three"); => 'one', 2, 'three'
#############
sub sql_quote{ map{ /^(\d+|NULL)$/ ? $_ : "\'$_\'" } @_ }

# Escape the list of parameters (all unsafe chars like ",' are escaped)
# We make a copy of @_ since we might try to change the passed values,
# producing an error when modification of a read-only value is attempted
##############
sub sql_escape{ my @a = @_; map { s/([\'\\])/\\$1/g;$_} @a }


# DESTROY makes all kinds of cleanups if the fuctions were interuppted
# before their completion and haven't had a chance to make a clean up.
###########
sub DESTROY{
  my $self = shift;

  $self->sql_unlock_tables() if $self->{lock};
  $self->{sth}->finish       if $self->{sth};
  $self->{dbh}->disconnect   if $self->{dbh};

} # end of sub DESTROY

# Don't remove
1;
