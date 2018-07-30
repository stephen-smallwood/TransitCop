#!/usr/bin/perl -w
#########################################
# Script to keep track of and clean up 
# areas of temporary storage.
# Written to be generic and use a config file
# in the form:
# basepath | lifetime | delete_dir | dir_lifetime
# Ensure the config file is read only for everyone except root.
# 090917 - SS
#
##########################################

use Getopt::Long;

my ($config,$log,$verbose,$help);
GetOptions(
   'config=s' => \$config,
   'verbose' => \$verbose,
   'help' => \$help,
);

if($help){
  &help_me;
}

open my $fh, "date '+%d-%m-%y %H:%M:%S' |" or die "cannot run command: $!";
while(<$fh>){
   $sdate = $_;
   chomp ($sdate);
}
close $fh;

print "Starting disk clean-up at $sdate \n";

if(!$config || ! -r "$config"){
   print "ERROR : Could not read config file. Exiting. \n";
   exit;
}

open CONFIG, "<$config" or die $!;

while(my $line = <CONFIG>){

   if($line =~ /(^#)/ || $line =~ /(^\s+$)/){
      next;
   }else{
      chomp($line);
      ($base,$life,$dd,$dlife) = split(/:/,$line);

      if(! defined $base){
         $base = "";
      }
      if(! defined $life){
         $life = "";
      }
      if(! defined $dd){
         $dd = "";
      }
      if(! defined $dlife){
         $dlife = "";
      }
      
      chop($base);
      $dd =~ s/\s+//g;
      $life =~ s/\s+//g;
      $dlife =~ s/\s+//g;

      if($verbose){
         print "Base : ..$base.. \n";
         print "Delete files older than : ..$life.. \n";
         print "Delete empty directories (d|l) : ..$dd.. \n";
         print "Delete directories older than: ..$dlife.. \n";
      }
   }

   if(($base !~ /^\/\w+/) || ($dd !~ /^d$|^l$/) || ($life !~ /^\d+$/) || ($dlife !~ /^\d+$/)){
  
      if($verbose){
         if($dd !~ /^d$|^l$/){
            print "dd is the problem \n";
         }elsif($base !~ /^\/\w+/){
            print "The base is the problem \n";
         }elsif($life !~ /^\d+$/){
            print "the life is the problem \n";
         }elsif($dlife !~ /^\d+$/){
            print "the dlife is the problem \n";
         }
      }
  
      print "Problem with options - Exit \n";
      exit;

   }else{
      if($verbose){
         print "Options OK \n";
      }
   }
   
   $stat_cmd='stat '.$base.' > /dev/null 2>&1';
   system($stat_cmd);

   $cmd='find '.$base.' -depth -type f -ctime +'.$life.' -mtime +'.$life.' -atime +'.$life.' -exec rm -fv {} \;';
   if($verbose){
      print "$cmd \n";
   }
   system($cmd);

   ################################################
   # have to do the echo as OSX does not know about
   # the -v option on rmdir_
   #################################################
   
   if($dd eq 'd'){
      $dcmd='find '.$base.' -depth -type d -empty -ctime +'.$dlife.' -mtime +'.$dlife.' -exec echo {} \; -exec rmdir {} \;';
      if($verbose){
         print "$dcmd \n";
      }
      system($dcmd);
   }
}

open my $efh, "date '+%d-%m-%y %H:%M:%S' |" or die "cannot run command: $!";
while(<$efh>){
   $edate = $_;
   chomp ($edate);
}
close $efh;

print "Finished disk clean-up at $edate. \n";

##### SUBS #######

sub help_me
{
    print "
    USAGE: TransitCop.pl [OPTIONS] --config=</path>
            
    This command will scan the file contents of a directory and update
    a database with what it finds.

    If the files have been there for more than a given number of days 
    they are deleted.

    If a directory is empty and the delete directory option is set the directory 
    will be deleted.
	    
    -c --config=<path>  path to config file which has the format:
                        basepath : lifetime : d|l
			Where:
			   basepath = directory to start scann from
			   lifetime = length files should be left on the system (days)
			   d|l = delete or leave empty directories
    -v --verbose	debug output
    -h --help		print this help
    \n";

     exit;
}
