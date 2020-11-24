#!/usr/bin/perl -w
    
# this script should be run from the crontab every night or in shorter
# intervals. This scripts does a few things.
# 1. dump all the tables into a separate dump files (these dump files 
# are ready for DB restore)
# 2. backups the last update log file and create a new log file

#This script originates from the perl.apache.org site, but I have adapted it to work
#properly with the newer versions of MySQL, where the log files are named differently
#WVW 14/02/2000 w@ba.be
    
use strict;

my $data_dir = "/var/lib/mysql";
my $update_log = "$data_dir/central2.001";
my $dump_dir  = "$data_dir/backup";
my $gzip_exec = "/bin/gzip";
my @db_names = qw(mysql besup);
my $mysql_admin_exec = "/usr/bin/mysqladmin ";
my $hostname = "central2";

my $password = "babedb";
    
# convert unix time to date + time
my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
my $time  = sprintf("%0.2d:%0.2d:%0.2d",$hour,$min,$sec);
my $date  = sprintf("%0.2d.%0.2d.%0.4d",++$mon,$mday,$year+1900);
my $timestamp = "$date.$time";
    
# dump all the DBs we want to backup
foreach my $db_name (@db_names) {
  my $dump_file = "$dump_dir/$timestamp.$db_name.dump";
  my $dump_command = "/usr/bin/mysqldump -c -e -l -q --flush-logs -p$password $db_name > $dump_file";
  system $dump_command;
}

mkdir "$dump_dir/$timestamp.log", 0;
`mv $data_dir/$hostname.[0-9]* $dump_dir/$timestamp.log`;
    
# move update log to backup for later restore if needed
#rename $update_log, "$dump_dir/$timestamp.log" if -e $update_log;

# restart the update log to log to a new file!
`/usr/bin/mysqladmin refresh -p$password`;

# compress all the created files
system "$gzip_exec $dump_dir/$timestamp.log/*";
system "$gzip_exec $dump_dir/$timestamp.*.dump*";
