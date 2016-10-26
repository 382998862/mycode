#!/usr/bin/perl
use strict;
use Encode;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);
#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#获取参数

###############Time
my $Time_start;
$Time_start=sub_format_datetime(localtime(time()));
print "\nStart Time:[$Time_start]\n\n";
################

my %opts;
GetOptions(\%opts,"i=s","o=s");
my $I = $opts{i} ;
my $O = $opts{o} ;

if (!defined($opts{i}))
{
                print <<"Usage End.";

         Description:
             -i                 information
			 
             -h                 help document

Usage End.
        exit;
}

open(F,"$I") or die "open error:$!";

my @lines=<F> ;

open(F1,">>var") or die "open error:$!";

my $i = 1;
my $str = "男";
$str = decode("GB2312",$str);
$str = encode("UTF-8",$str);

my $f1 = 0 ;
my $f2 = 0 ;
my $f5 = 0 ;
my $f  = 0 ;
while($i < @lines){
                chomp $lines[$i];
                my @l = split "\t",$lines[$i];
                $lines[$i] =~ s/\r//g;
                $lines[$i] =~ s/\n//g;
                #$l[0]  样品编号
                #$l[1]  姓名
                #$l[2]  性别
                #$l[3]  年龄
                #$l[4]  送样时间
                #$l[5]  报告时间
                #$l[6]  1F基因型
                #$l[7]  2F基因型
                #$l[8]  5F基因型
                if($l[6] eq "CC")
                {$f1 = 0 ;}
                if($l[6] eq "CT")
                {$f1 = 10;}
                if($l[6] eq "TT")
                {$f1 = 50;}
                if($l[7] eq "AA")
                {$f2 = 0 ;}
                if($l[7] eq "AG")
                {$f2 = 25;}
                if($l[7] eq "GG")
                {$f2 = 25;}
                if($l[8] eq "TT")
                {$f5 = 0 ;}
                if($l[8] eq "TG")
                {$f5 = 0 ;}
                if($l[8] eq "GG")
                {$f5 = 25;}
                #计算总得分
                $f = $f1 + $f2 + $f5 ;
                if($l[2] eq $str)
                {
                    if($f >= 50)
                    {
                    print F1 "0-1.pdf"."\t".$lines[$i]."\t"."2-4.pdf"."\t"."3-4.pdf"."\t".$f."\n";
                    }
                    if($f == 25 || $f == 35)
                    {
                    print F1 "0-1.pdf"."\t".$lines[$i]."\t"."2-3.pdf"."\t"."3-3.pdf"."\t".$f."\n";
                    }
                    if($f == 10)
                    {
                    print F1 "0-1.pdf"."\t".$lines[$i]."\t"."2-2.pdf"."\t"."3-2.pdf"."\t".$f."\n";
                    }
                    if($f == 0)
                    {
                    print F1 "0-1.pdf"."\t".$lines[$i]."\t"."2-1.pdf"."\t"."3-1.pdf"."\t".$f."\n";
                    }
                }
                else
                {
                    if($f >= 50)
                    {
                    print F1 "0-2.pdf"."\t".$lines[$i]."\t"."2-4.pdf"."\t"."4-4.pdf"."\t".$f."\n";
                    }
                    if($f == 25 || $f == 35)
                    {
                    print F1 "0-2.pdf"."\t".$lines[$i]."\t"."2-3.pdf"."\t"."4-3.pdf"."\t".$f."\n";
                    }
                    if($f == 10)
                    {
                    print F1 "0-2.pdf"."\t".$lines[$i]."\t"."2-2.pdf"."\t"."4-2.pdf"."\t".$f."\n";
                    }
                    if($f == 0)
                    {
                    print F1 "0-2.pdf"."\t".$lines[$i]."\t"."2-1.pdf"."\t"."4-1.pdf"."\t".$f."\n";
                    }
                }
        $i++;
}
close(F);
close(F1);

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
# calculate the total run time
# ------------------------------------------------------------------
sub run_time {
	# get parameter
	my ($start_time) = @_;

	# calculate the run time
	my $run_time = time() - $start_time;

	# log
	log_current_time("Total elapsed time: ${run_time}s");
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
