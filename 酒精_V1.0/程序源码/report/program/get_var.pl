#!/usr/bin/perl
use strict;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#获得输入tex文件的变量

###############Time
my $Time_start;
$Time_start=sub_format_datetime(localtime(time()));
print "\nStart Time:[$Time_start]\n\n";
################


my %opts;
GetOptions(\%opts,"i=s",);
my $I  = $opts{i} ;

if (!defined($opts{i}))
{
		print <<"Usage End.";
	
	 Description:

             -i                 liquor

Usage End.
	exit;
}

open(F1,"/share/nas1/sunqh//product/jj/report/program/reference.txt") or die "open error:$!";
open(F2,"$I") or die "open error:$!";
open(F,">>var") or die "open error:$!";
#open(F4,">>gene-cover") or die "open error:$!";

my @lines1=<F1> ;
my @lines2=<F2> ;
#print $lines1[1];

my $i = 0;

while($i < @lines2){
    chomp $lines1[$i];
    my @l = split "\t",$lines2[$i];
    #print $l[2],$l[3];
    $lines2[$i] =~ s/\n//;
    my $length = length($l[1]);
    #print $length ;
    if($length == 6 )
    {
                if($l[2] eq "AA")
                {
                   if($l[3] eq "GG")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[1];
                   }
                   if($l[3] eq "AG" || $l[3] eq "GA")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[2];
                   }
                   if($l[3] eq "AA")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[3];
                   }

                }

                if($l[2] eq "GA" || $l[2] eq "AG")
                {
                   if($l[3] eq "GG")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[4];
                   }
                   if($l[3] eq "AG" || $l[3] eq "GA")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[5];
                   }
                   if($l[3] eq "AA")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[6];
                   }

                }

                if($l[2] eq "GG")
                {
                   if($l[3] eq "GG")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[7];
                   }
                   if($l[3] eq "AG" || $l[3] eq "GA")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[8];
                   }
                   if($l[3] eq "AA")
                   {
                   print F $lines2[$i]."\t"."79,491"."\t".$lines1[9];
                   }

                }
    }
    else
    {
                if($l[2] eq "AA")
                {
                   if($l[3] eq "GG")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[1];
                   }
                   if($l[3] eq "AG" || $l[3] eq "GA")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[2];
                   }
                   if($l[3] eq "AA")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[3];
                   }

                }

                if($l[2] eq "GA" || $l[2] eq "AG")
                {
                   if($l[3] eq "GG")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[4];
                   }
                   if($l[3] eq "AG" || $l[3] eq "GA" )
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[5];
                   }
                   if($l[3] eq "AA")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[6];
                   }

                }

                if($l[2] eq "GG")
                {
                   if($l[3] eq "GG")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[7];
                   }
                   if($l[3] eq "AG" || $l[3] eq "GA")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[8];
                   }
                   if($l[3] eq "AA")
                   {
                   print F $lines2[$i]."\t"."64,491"."\t".$lines1[9];
                   }

                }
    }
    $i++;
}
close(F1);
close(F2);


print "T\n" ;



###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd Time :[$Time_End]\n\n";
##############


sub sub_format_datetime
{
        #Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
        $wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

# ------------------------------------------------------------------
# print current time with some information
# ------------------------------------------------------------------
sub log_current_time {
	# get parameter
	my ($info) = @_;

	# get current time with string
	my $curr_time = format_datetime(localtime(time()));

	# print info with time
	print "[$curr_time] $info\n";
}

# ------------------------------------------------------------------
# mkdir dir and check, if failed, then program will die
# ------------------------------------------------------------------
sub mkdir_or_die {
	# get parameter
	my ($dir) = @_;

	# check and mkdir
	`mkdir -p $dir` if(!-d $dir);

	# check mkdir result
	if(!-d $dir) {
		log_and_exit("Error: mkdir \"$dir\" is failed");
	}
}

# ------------------------------------------------------------------
# log_current_time() and exit(1)
# ------------------------------------------------------------------
sub log_and_exit {
	# log
	log_current_time(shift);
	# exit
	#exit(1);
	die;
}

# ------------------------------------------------------------------
# run cmd and check run status
# ------------------------------------------------------------------
sub run_cmd_or_die {
	# get parameter
	my ($cmd) = @_ ;

	# get cmd staring time
	my $start_time=time();

	# run cmd and check
	log_current_time("starting cmd: $cmd");
	my $flag = system($cmd) ;
	if ($flag != 0){
		log_and_exit("Error: command failed: $cmd");
	} else {
		log_current_time("end cmd: $cmd");
		run_time($start_time);
	}
}

# ------------------------------------------------------------------
# calling qsub
# ------------------------------------------------------------------
sub qsub {
	# get parameter
	my ($shfile, $maxproc, $queue) = @_ ;

	# check parameters
	if( ($queue ne "general.q") && ($queue ne "middle.q") && ($queue ne "great.q") ){
		log_and_exit("qsub queue error: quene($queue) not general.q, middle.q, or great.q");
	}

	# create cmd
	my $cmd = "";
	# at the cluster node
	if (`hostname` =~ /cluster/) {
		$cmd = "qsub-sge.pl --queue $queue --maxproc $maxproc --independent --reqsub $shfile" ;
	# at computing node
	} else {
		$cmd = "ssh cluster -Y qsub-sge.pl --queue $queue --maxproc $maxproc --independent --reqsub $shfile" ;
	}

	# run
	run_cmd_or_die($cmd);
}


# ------------------------------------------------------------------
# get absolute path for file or dir
# ------------------------------------------------------------------
sub absolute_path {
	# get parameter
	my ($in, $cur_dir) = @_;
	my $return = "";

	# get absolute path for file
	if(-f $in) {
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;
		$dir=`pwd`;
		chomp $dir;
		$return="$dir/$file";
	# get absolute path for dir
	} elsif(-d $in) {
	        chdir $in;
		$return=`pwd`;
		chomp $return;
	# error
	} else {
	        log_and_exit("Warning just for file and dir");
	}

	# reset current work dir
	chdir $cur_dir;
	# return
	return $return;
}
