#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#bwa比对提取比对信息

###############Time
my $Time_start;
$Time_start=sub_format_datetime(localtime(time()));
print "\nStart Time:[$Time_start]\n\n";
################

my %opts;
GetOptions(\%opts,"r=s" ,"c=s" ,"cr=s","s=s");
my $I1  = $opts{r} ;                 #参考基因组文件
my $I2  = $opts{c} ;                 #比对基因组文件目录
my $O1 = $opts{cr} ;                 #Blast比对结果
my $O2 = $opts{s} ;                  #生成的位点信息

if (!defined($opts{r})||!defined($opts{c})||!defined($opts{cr})||!defined($opts{s}))
{
                print <<"Usage End.";

         Description:


             -r                 reference genome file                                 must be given

             -c                 genome comparison file dir                            must be given

             -cr                blast alignment results 
			 
			 -s                 generate site information
			 
			 -h                 help document

Usage End.
        exit;
}

my @dir;
my $filename;
my $dirname = "$I2/";         #指定一个目录
opendir ( DIR, $dirname ) || die "Error in opening dir $dirname\n";
while( ($filename = readdir(DIR))){
if($filename =~ /.fa/) {
   print "$filename\n";

   #rename "$I2/$filename","$I2/$newfile" ;  #重命名
   foreach($filename)         #遍历文件
   {
   #open(FILE,">>e:/a/".$filename) or die "open error:$!";
   #print FILE "bbb";                                     #例子
   #close (FILE);
   my $newfile = $filename;
   my $c=(split(/-|_/,$filename))[0];
   $newfile=$c;
   print "$newfile\n";

open(FILE4,">$O1") or die "open error:$!";
my $systemcheck1 = system("formatdb -i $I1 -p F -o T") ; #调用系统 建库命令
my $systemcheck2 = system("blastall -p blastn -d $I1 -i $I2/$filename -o $O1 -m 8 ");
#Blast比对生成比对结果文件

close(FILE4);

my $fileExist = -e "$O2";
unless( $fileExist )
{
        open(FILE3,">>$O2") or die "open error:$!";
        print FILE3 "number:\tprimers:\tsites location :\t sites information : \n" ;
        close(FILE3);
}

open(FILE3,">>$O2") or die "open error:$!";
open(FILE2,"$I2/"."$filename") or die "open error:$!";
my @string;
@string =<FILE2>;
#$string[0] = "$newfile" ;
print FILE3 "$newfile";
print FILE3 "\t$I2";
$string[0] = "";
#print "@string";
my $b="";
for (my $i=0;$i<@string;$i++)
    {
           chomp($string[$i]);
       $b= $b.$string[$i];      #将比对文件处理成字符串
    }
#$b=~ s/\n//g;
#$b=~ s/" "//g;
$b=~ s/\s//g;

my %hash;
my $a;
my $d;
my $e;
open(FILE1,"$O1") or die "open error:$!";
while(<FILE1>){
        chomp;
        my @hash;
        @hash=split;
        $hash[1] =~ s/rs\d+_\d+_//g;
        #print"$hash[1] \n";

     if($hash[9] > $hash[8])
     {
        if($hash[1] <= $hash[9] && $hash[1] >= $hash[8])
        {
        $e = $hash[3]-($hash[9]-$hash[8]+1) ;  #参考空位数
        $d = $hash[3]-($hash[7]-$hash[6]+1) ;  #比对空位数
        $a=$hash[1] - $hash[8]+ $hash[6] ;
        #print FILE3 "\t$a"       #在参考基因组中位点位置与起始位置的差
        print FILE3 "\t","$a"-"$d"+"$e";
        }
     }
     else
     {
       if($hash[1] <= $hash[8] && $hash[1] >= $hash[9])
        {
        $e = $hash[3]-($hash[8]-$hash[9]+1) ;  #参考空位数
        $d = $hash[3]-($hash[7]-$hash[6]+1) ;  #比对空位数
        $a=$hash[8] - $hash[1]+ $hash[6] ;
        #print FILE3 "\t$a";  #在参考基因组中位点位置与起始位置的差
        print FILE3 "\t","$a" - "$d" + "$e";
        }
     }
}
close(FILE1);



#print FILE3 "\t$b" ;
print FILE3 "\t", substr($b,$a-$d+$e-1,1);  #在比对基因组中位点位置
print FILE3 "\n";
#print length($b);
close(FILE2);
close(FILE3);

   }
}
}



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
