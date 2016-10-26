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
#根据样本基本信息计算酒量，生成模板中所需的变量信息；


###############Time
my $Time_start;
$Time_start=sub_format_datetime(localtime(time()));
print "\nStart Time:[$Time_start]\n\n";
################


my %opts;
GetOptions(\%opts,"i=s");
my $I  = $opts{i} ;

if (!defined($opts{i}))
{
                print <<"Usage End.";

         Description:


             -i                   information

Usage End.
        exit;
}


open(F1,"$I") or die "open error:$!";
open(F,">>liquor") or die "open error:$!";
my @lines1=<F1> ;

my  $moisture;    #含水量；
my  $quality;     #代谢的乙醇质量；
my  $volume;      #代谢的乙醇体积；
my  $degree4;     #4度饮酒量（ml）；
my  $degree12;    #12度饮酒量（ml）；
my  $degree38;    #38度饮酒量（ml）；
my  $degree53;    #53度饮酒量（ml）；
my  $degree60;    #60度饮酒量（ml）；
my  $i = 1;
my $str = "两";
$str = decode("GB2312",$str);
$str = encode("UTF-8",$str);
my $str1 = "男";
$str1 = decode("GB2312",$str1);
$str1 = encode("UTF-8",$str1);
#print F3 $l[6].$str."\n";
while($i < @lines1){
                chomp $lines1[$i];
                my @l1 = split "\t",$lines1[$i];

                #$l1[0]=number; $l1[1]=name;   $l1[2]=sex;   $l1[3]=age;
                #$l1[4]=height; $l1[5]=weight; $l1[6]3Fgene; $l1[7]=4Fgene;

                #my $fileExist = -e "e:/$l1[0].liquor.xls";
                #unless( $fileExist )
                #{
                #      open(F,">>e:/$l1[0].liquor.xls") or die "open error:$!";
                #      print F "\t啤酒（4°）\t红酒（12°）\t白酒（38°）\t白酒（53°）\t白酒（60°）\n" ;
                #      close(F);
                #}

                #open(F,">>e:/$l1[0].liquor.xls") or die "open error:$!";


                if($l1[2] eq $str1)
                {
                $moisture = 2.447 - 0.09516*$l1[3] + 0.1074*$l1[4] + 0.3362*$l1[5] ;
                    if($l1[6] eq "GG")
                    {
                    $quality = 0.64*$l1[5]*$l1[5]/$moisture*0.3;
                    $volume  = $quality/0.7893;
                    }
                    else
                    {
                    $quality = 0.64*$l1[5]*$l1[5]/$moisture*0.2;
                    $volume  = $quality/0.7893;
                    }
                }
                else
                {
                $moisture = -2.097 + 0.1069*$l1[4] + 0.2466*$l1[5] ;
                    if($l1[6] eq "GG")
                    {
                    $quality = 0.64*$l1[5]*$l1[5]/$moisture*0.3;
                    $volume  = $quality/0.7893;
                    }
                    else
                    {
                    $quality = 0.64*$l1[5]*$l1[5]/$moisture*0.2;
                    $volume  = $quality/0.7893;
                    }

                }

                $degree4   = ($volume/0.04) ;
                $degree12  = ($volume/0.12) ;
                $degree38  = ($volume/0.38) ;
                $degree53  = ($volume/0.53) ;
                $degree60  = ($volume/0.6 )  ;

                $degree4  = sprintf("%.0f", $degree4) ;
                $degree12 = sprintf("%.0f", $degree12);
                $degree38 = sprintf("%.0f", $degree38);
                $degree53 = sprintf("%.0f", $degree53);
                $degree60 = sprintf("%.0f", $degree60);
                my $degree38_50 =($degree38)/50;
                my $degree53_50 =($degree53)/50;
                my $degree60_50 =($degree60)/50;
                $degree38_50 =sprintf("%.1f", $degree38_50);
                $degree53_50 =sprintf("%.1f", $degree53_50);
                $degree60_50 =sprintf("%.1f", $degree60_50);




                print F $l1[0],"\t",$l1[1],"\t",$l1[6],"\t",$l1[7],"\t",$degree4."ml","\t",$degree12."ml","\t",($degree38_50).$str,"\t",($degree53_50).$str,"\t",($degree60_50).$str,"\t",(($degree4)*2)."ml","\t",(($degree12)*2)."ml","\t",(($degree38_50)*2).$str,"\t",(($degree53_50)*2).$str,"\t",(($degree60_50)*2).$str,"\t",(($degree4)*4)."ml","\t",(($degree12)*4)."ml","\t",(($degree38_50)*4).$str,"\t",(($degree53_50)*4).$str,"\t",(($degree60_50)*4).$str,"\n";


                $i++;
}
close(F1);

print "T" ;



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
