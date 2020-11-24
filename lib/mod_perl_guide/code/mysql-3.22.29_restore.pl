#!/usr/bin/perl -w

# this scripts restores the DBs

# Usage: mysql.restore.pl update.log.gz dump.db1.gz [... dump.dbn.gz]
# all files dump* are compressed as we expect them to be created by 
# mysql.backup utility

# example: 
# % mysql.restore.pl myhostname.log.gz 12.10.1998.16:37:12.*.dump.gz

# .dump.gz extension.

use strict;

use FindBin qw($Bin);

my $data_dir   = "/var/lib/mysql";
my $dump_dir   = "$data_dir/dump";
my $gzip_exec  = "/bin/gzip";
my $mysql_exec = "/usr/bin/mysql -f ";
my $mysql_backup_exec = "$Bin/mysql.backup.pl";
my $mysql_admin_exec  = "/usr/bin/mysqladmin ";

my $update_log_file = '';
my @dump_files = ();

# split input files into an update log and the dump files
foreach (@ARGV) {
  push(@dump_files, $_),next unless /\.log\.gz/;
  $update_log_file = $_;
}

die "Usage: mysql.restore.pl update.log.gz dump.db1.gz [... dump.dbn.gz]\n" 
  unless defined @dump_files and @dump_files > 0;

# load the dump files
foreach (@dump_files) {

    # check the file exists
  warn("Can't locate $_"),next unless -e $_;

    # extract the db name from the dump file
  my $db_name = $1 if /\d\d\.\d\d.\d\d.\d\d:\d\d:\d\d\.(\w+)\.dump\.gz/;

  warn("Can't extract DB name from the file name,
        probably an error in the file format"),
          next unless defined $db_name and $db_name;

    # we want to drop the table since restore will rebuild it!
    # force to drop the db without confirmation
  my $drop_command = "$mysql_admin_exec -f drop $db_name";
  system $drop_command;

  $drop_command = "$mysql_admin_exec create $db_name";
  system $drop_command;

    # build the command and execute it
  my $restore_command = "$gzip_exec -cd $_ | $mysql_exec $db_name";
  system $restore_command;
}

# now load the update_log file (update the db with the changes since
# the last dump
warn("Can't locate $update_log_file"),next unless  -e $update_log_file;

my $restore_command = 
  "$gzip_exec -cd $update_log_file |$mysql_exec";
system $restore_command;

# rerun the mysql.backup.pl since we have reloaded the dump files
# and update log , and we must rebuild backups!
system $mysql_backup_exec;
