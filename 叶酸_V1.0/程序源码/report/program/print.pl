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
#生成tex文件

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
             -i                 var
			 
             -h                 help document

Usage End.
        exit;
}

open(F,"$I") or die "open error:$!";

my @lines=<F> ;


my $str1 = "姓";
$str1 = decode("GB2312",$str1);
$str1 = encode("UTF-8",$str1);
my $str2 = "名：";
$str2 = decode("GB2312",$str2);
$str2 = encode("UTF-8",$str2);
my $str3 = "年";
$str3 = decode("GB2312",$str3);
$str3 = encode("UTF-8",$str3);
my $str4 = "龄：";
$str4 = decode("GB2312",$str4);
$str4 = encode("UTF-8",$str4);
my $str5 = "样本编号：";
$str5 = decode("GB2312",$str5);
$str5 = encode("UTF-8",$str5);
my $str6 = "样本类型：";
$str6 = decode("GB2312",$str6);
$str6 = encode("UTF-8",$str6);
my $str7 = "口腔黏膜脱落细胞";
$str7 = decode("GB2312",$str7);
$str7 = encode("UTF-8",$str7);
my $str8 = "送检日期：";
$str8 = decode("GB2312",$str8);
$str8 = encode("UTF-8",$str8);
my $str9 = "报告日期：";
$str9 = decode("GB2312",$str9);
$str9 = encode("UTF-8",$str9);

my $i = 0;
while($i < @lines)
{
                chomp $lines[$i];
                my @l = split "\t",$lines[$i];
                #print $l[0];
                #$l[0]   男女封皮
                #$l[1]   样本编号
                #$l[2]   姓名
                #$l[3]   性别
                #$l[4]   年龄
                #$l[5]   送样时间
                #$l[6]   报告时间
                #$l[7]   1F基因型
                #$l[8]   2F基因型
                #$l[9]   5F基因型
                #$l[10]  第二张图片
                #$l[11]  第三张图片
                #$l[12]  判断强弱的得分
                open(F1,">>$O/$l[1].tex") or die "open error:$!";
                print F1 "

\\documentclass[a4paper]{article}
\\usepackage{pdfpages}
\\usepackage{wallpaper}
\\usepackage{longtable}
\\usepackage{ctex}
\\usepackage{setspace}
\\usepackage{xeCJK}
\\setCJKfamilyfont{kai}{KaiTi}
\\newcommand{\\kai}{\\CJKfamily{kai}}
\\pagestyle{empty}
\\begin{document}
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/$l[0]}
\\null
\\clearpage
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/1.pdf}
\\null
\\clearpage
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/$l[10]}
\\renewcommand\\arraystretch{1.49}
\\vskip 15pt
\\kai\\large\\begin{longtable}{p{3.2cm}p{3cm}p{5.35cm}}
&$str1\\quad $str2&$l[2]\\\\
&$str3\\quad $str4&$l[4]\\\\
&$str5&$l[1]\\\\
&$str6&$str7\\\\
&$str8&$l[5]\\\\
&$str9&$l[6]\\\\
\\end{longtable}
\\clearpage
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/$l[11]}
\\null
\\clearpage
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/5.pdf}
\\null
\\clearpage
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/6.pdf}
\\null
\\clearpage
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/7.pdf}
\\null
\\clearpage
\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/sunqh//product/ys/report/tex/8.pdf}
\\null
\\clearpage
\\end{document}
";
close(F1);
$i++;
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
