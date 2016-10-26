#!/usr/local/bin/perl -w
# 
# Copyright (c) BMK 2009
# Writer:         Yangsh <yangsh@biomarker.com.cn>
# Program Date:   2010.
# Modifier:       Yangsh <yangsh@biomarker.com.cn>
# Last Modified:  2010.
my $ver="1.0.1";
my $BEGIN=time();

use strict;
use Cwd;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

######################请在写程序之前，一定写明时间、程序用途、参数说明；每次修改程序时，也请做好注释工作

if (@ARGV!=3) 
{
	print "Usage: <Q> <fqdir> <outdir> \n";
	print "\n\tQ : 33 or 64\n\tfqdir: xxx001.R22s4_20111205_1.fq \t [optional] xxx001.R22s4_20111205_2.fq \n";
	exit;
}

###############Time
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";
################
my $pwd=`pwd`;chomp($pwd);
my $programe_dir=basename($0);
my $path=dirname($0);
my ($Q,$indir,$od)=@ARGV;
$indir=ABSOLUTE_DIR($indir,$pwd);
my @fq=glob("$indir/*fq");
`mkdir $od/work_sh -p` if(!-d "$od/work_sh");
$od=ABSOLUTE_DIR($od,$pwd);
my $queue="general.q";
################ perl ################
my $GC_Q_SVG_pl ="$Bin/GCcont_Solexa_check.pl";
my $qual=        "$Bin/GCqual_Solexa_check.pl";
my $cycle_Q_svg_pl = "$Bin/Cycle_Q_SVG.pl";
my $svg2png     ="/share/nas2/genome/biosoft/distributing_svg_4.74/svg2xxx_release/svg2xxx";

################ xxxx ################

my %fqpair;
my $limit=0;
foreach  (@fq) 
{
	my $file=basename($_);
	if ($file=~/(\w+)_([12])\.fq/) {
		my $id=$2;
		my $name=$file;
		$name=~s/\_1\.fq//;
		$name=~s/\_2\.fq//;
		$name=~s/_good//;
		$fqpair{$name}{$id}=$file;
		$limit=1 if $id==2;
		
	}else{
		print "There are fq_names formate error in $indir\n Plese Check and good luck !!!\n";
		exit;
	}
}

#print Dumper %fqpair;
my %cycle_percent;
open (OUT,">$od/work_sh/GC_Q_svg.sh");
foreach my $flag (sort keys %fqpair) {
	my $fq1=$fqpair{"$flag"}{"1"};
	if ($limit==1) {
		my $fq2=$fqpair{"$flag"}{"2"};
		print OUT "cd  $od && /share/nas1/sunqh/DNA_Rec/bin/fastq_qc_stat -Q $Q -a  $indir/$fq1 -b $indir/$fq2 -f $flag -m 512 -q 45 && ";
	}
	else {print OUT "cd $od && /share/nas1/sunqh/DNA_Rec/bin/fastq_qc_stat -Q $Q -a  $indir/$fq1 -f $flag -m 512 -q 45 && ";}
	print OUT "perl $GC_Q_SVG_pl -gc $od/$flag.acgtn -od $od/ &&";
	print OUT "perl $qual -qu $od/$flag.quality -od $od/ &&";
	print OUT "perl $cycle_Q_svg_pl -i $od/$flag.quality -o $od/$flag \n";
}
close(OUT);

my $qstatN=`qstat|wc`;$qstatN=~s/^\s+//;$qstatN=(split/\s+/,$qstatN)[0];
my $qsubNum=$qstatN+50;
`sh  $od/work_sh/GC_Q_svg.sh `;
################ stat ################
my @STAT=glob("$od/*.stat");
my @Paraf;
foreach my $stat (@STAT) {
	push @Paraf,$stat unless $stat=~/.+cycleQ\.stat/;
}

open (OUT,">$od/AllSample_GC_Q.stat");
print OUT "SampleID\tReadSum\tBaseSum\tGC(%)\tN(%)\tQ20(%)\tCycleQ20(%)\tQ30(%)\n";
foreach my $paraf (@Paraf) 
{
	my $now;
	my $file=basename($paraf);
	$file=~s/\.stat$//;
	open(IN,"$paraf")||die"can't open $paraf\n";
	<IN>;
	while (<IN>)
	{
		chomp;
		my @A=split/\s+/,$_,2;
#		$now="$file\t$A[1]\n";
		print OUT "$file\t$A[1]\n" if ($_=~/read_AB/);
	}
	close(IN);

}
close(OUT);

`cd $od && perl $svg2png ./ PNG && cd ../ `;

###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd Time :[$Time_End]\n\n";
&Runtime($BEGIN);

#+---------------------
#        Subs         |
#+---------------------

sub MKDIR
{ # &MKDIR($out_dir);
	my ($dir)=@_;
	rmdir($dir) if(-d $dir);
	mkdir($dir) if(!-d $dir);
}

sub Runtime
{ # &Runtime($BEGIN);
	my ($t1)=@_;
	my $t=time()-$t1;
	print "Total elapsed time: ${t}s\n";
}
sub Done
{
	my ($out)=@_;
	print "$out Done ~ ......\n";
}
sub sub_format_datetime {#Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
sub ABSOLUTE_DIR
{
        my ($in,$cur_dir)=@_;
        my $return="";

        if(-f $in)
        {
                my $dir=dirname($in);
                my $file=basename($in);
                chdir $dir;$dir=`pwd`;chomp $dir;
                $return="$dir/$file";
        }
        elsif(-d $in)
        {
                chdir $in;$return=`pwd`;chomp $return;
        }
        else
        {
                warn "Warning just for file and dir\n";
                exit;
        }
        chdir $cur_dir;
        return $return;
}
