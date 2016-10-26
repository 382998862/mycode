#!/usr/bin/perl
use strict;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#输出tex文件


###############Time
my $Time_start;
$Time_start=sub_format_datetime(localtime(time()));
print "\nStart Time:[$Time_start]\n\n";
################


my %opts;
GetOptions(\%opts,"i=s","o=s");
my $I  = $opts{i} ;
my $O  = $opts{o} ;

if (!defined($opts{i})||!defined($opts{o}))
{
		print <<"Usage End.";
	
	 Description:

             -i                   var
			 
			 -o                   Output directory

Usage End.
	exit;
}

#print encode("gb2312",decode("utf8","两"));
open(F1,"$I") or die "open error:$!";


my @lines=<F1> ;

my $i = 0;
while($i < @lines){
                chomp $lines[$i];
                my @l = split "\t",$lines[$i];
                #print $l[0],$l[3] ;
###################################################
#$l[0] = number
#$l[1] = name
#$l[2] = 3F
#$l[3] = 4F
#$l[4] = 酒量1
#$l[5] = 酒量2
#$l[6] = 酒量3
#$l[7] = 酒量4
#$l[8] = 酒量5
#$l[9] = 酒量6
#$l[10]= 酒量7
#$l[11]= 酒量8
#$l[12]= 酒量9
#$l[13]= 酒量10
#$l[14]= 酒量11
#$l[15]= 酒量12
#$l[16]= 酒量13
#$l[17]= 酒量14
#$l[18]= 酒量15
#$l[19]= 姓名坐标
#$l[20]= 3F
#$l[21]= 4F
#$l[22]= 等级
#$l[23]= 百分比
#$l[24]= 打分
#$l[25]= 打分坐标
#$l[26]= 第二张图
#$l[27]= 第三张图
#$l[28]= 百分比
#$l[29]= 乙醇代谢能力
#$l[30]= 乙醛代谢能力
#$l[31]= 健康建议第一段
#$l[32]= 健康建议第二段
#$l[33]= 健康建议第三段
#$l[34]= 健康建议第四段
######################################################

                #print encode($l[33])
                #print $l[33] ;

                open(F2,">>$O/$l[0].tex") or die "open error:$!";
                print F2
"
\\documentclass{article}
\\usepackage{pdfpages}
\\usepackage[abs]{overpic}
\\usepackage{geometry}
\\usepackage{color}
\\usepackage{ctex}
\\usepackage{xeCJK}
\\usepackage{longtable}
\\usepackage{colortbl} %extraweight
\\usepackage{booktabs} %\\toprule
\\usepackage{wallpaper}



\\geometry{top=0cm, bottom=0cm, left=-0.7cm, right=0cm}


\\setCJKfamilyfont{hkljh}{DFPLiJinHeiW8}
\\newcommand{\\hkljh}{\\CJKfamily{hkljh}}

\\setCJKfamilyfont{fzdbs}{FZDaBiaoSong-B06S}
\\newcommand{\\fzdbs}{\\CJKfamily{fzdbs}}

\\setCJKfamilyfont{fzhtj}{FZHei-B01S}
\\newcommand{\\fzhtj}{\\CJKfamily{fzhtj}}

\\setCJKfamilyfont{wryh}{Microsoft YaHei}
\\newcommand{\\wryh}{\\CJKfamily{wryh}}

\\setCJKfamilyfont{fzdhj}{FZDaHei-B02S}
\\newcommand{\\fzdhj}{\\CJKfamily{fzdhj}}

\\newcommand{\\ei}{\\fontsize{6pt}{\\baselineskip}\\selectfont} %not8.5

\\begin{document}

\\begin{overpic}[width=140mm,height=210mm]{/share/nas1/sunqh//product/jj/report/tex/1.pdf}
\\special{papersize=140mm,210mm}
\\end{overpic}




\\begin{overpic}[width=140mm,height=210mm]{/share/nas1/sunqh//product/jj/report/tex/$l[26]}
%\\begin{overpic}{$l[26]}
\\special{papersize=140mm,210mm}
\\put($l[19]){\\fontsize{15pt}{10pt}\\selectfont{\\textcolor[rgb]{0.388,0.216,0.082}{\\wryh{$l[1]}}}}
\\put(177,465){\\fontsize{22pt}{10pt}\\selectfont{\\textcolor[rgb]{0.231,0.392,0.22}{\\textbf{\\wryh{$l[23]\\%}}}}}
\\put($l[25]){\\fontsize{24pt}{10pt}\\selectfont{\\textcolor[rgb]{0,0,0}{\\textbf{\\wryh{$l[24]}}}}}
\\end{overpic}
\\clearpage


\\begin{overpic}[width=140mm,height=210mm]{/share/nas1/sunqh//product/jj/report/tex/$l[27]}
\\special{papersize=140mm,210mm}
\\put(199,280){\\fontsize{20pt}{5pt}\\selectfont{\\textcolor[rgb]{0.655,0.176,0.357}{\\textbf{\\wryh{$l[28]\\%}}}}}
\\end{overpic}
\\clearpage

\\ULCornerWallPaper{0.76}{/share/nas1/sunqh//product/jj/report/tex/4.pdf}
\\special{papersize=140mm,210mm}
\\vspace*{5.85cm}
\\begin{longtable}{p{0.15cm}p{2.15cm}p{0.93cm}}
& \\parbox[t][0.65cm][s]{2cm} {\\fontsize{9pt}{10pt}\\selectfont{\\textcolor[rgb]{0.876,0.706,0.522}{\\wryh{$l[29]}}}}&\\\\
\\end{longtable}
\\vspace*{2.4cm}
\\begin{longtable}{p{0.15cm}p{2.15cm}p{0.93cm}}
& \\parbox[c][0.65cm][t]{2cm} {\\fontsize{9pt}{8pt}\\selectfont{\\textcolor[rgb]{0.876,0.706,0.522}{\\wryh{$l[30]}}}}&\\\\
\\end{longtable}
\\clearpage

\\ULCornerWallPaper{0.76}{/share/nas1/sunqh//product/jj/report/tex/5.pdf}
\\special{papersize=140mm,210mm}
\\vspace*{3.7cm}

\\begin{longtable}{p{1.35cm}p{1.35cm}p{1.35cm}p{1.35cm}p{1.35cm}p{3.85cm}}
\\vspace*{0.25cm}
\\wryh\\ei{$l[4]}&\\wryh\\ei{$l[5]}&\\wryh\\ei{$l[6]}&\\wryh\\ei{$l[7]}&\\wryh\\ei{$l[8]}&\\\\
\\vspace*{0.25cm}
\\wryh\\ei{$l[9]}&\\wryh\\ei{$l[10]}&\\wryh\\ei{$l[11]}&\\wryh\\ei{$l[12]}&\\wryh\\ei{$l[13]}&\\\\
\\vspace*{0.25cm}
\\wryh\\ei{$l[14]}&\\wryh\\ei{$l[15]}&\\wryh\\ei{$l[16]}&\\wryh\\ei{$l[17]}&\\wryh\\ei{$l[18]}&\\\\
\\end{longtable}
\\clearpage

\\ULCornerWallPaper{0.76}{/share/nas1/sunqh//product/jj/report/tex/6.pdf}
\\special{papersize=140mm,210mm}
\\vspace*{3.9cm}
\\begin{longtable}{p{0cm}p{5.1cm}p{3.85cm}}
 & \\parbox[t][7cm][s]{5.1cm} {\\fontsize{9pt}{9pt}\\selectfont{\\textcolor[rgb]{0.584,0.306,0.176}{\\wryh{ \\hspace*{5mm}$l[31]\\\\ \\hspace*{5mm} $l[32]\\\\ \\hspace*{5mm} $l[33]\\\\  \\hspace*{5mm} $l[34]}}}} & \\\\
\\end{longtable}
\\clearpage

\\ULCornerWallPaper{0.76}{/share/nas1/sunqh//product/jj/report/tex/7.pdf}
\\special{papersize=140mm,210mm}
\\null
\\clearpage

\\ULCornerWallPaper{0.76}{/share/nas1/sunqh//product/jj/report/tex/8.pdf}
\\special{papersize=140mm,210mm}
\\null
\\clearpage


\\end{document}

 ";

 $i++;
}

print "T\n";



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






