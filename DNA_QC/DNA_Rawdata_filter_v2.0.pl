#!/usr/bin/perl -w
use strict;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $BEGIN_TIME=time();
my $version="1.0.0";
#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($fIn,$fOut,$t,$cpu,$cut,$config,$lowp,$lowq,$Run);
GetOptions(
				"help|?" =>\&USAGE,
				"o:s"=>\$fOut,
				"i:s"=>\$fIn,
				"config:s"=>\$config,
				"Run:s"=>\$Run,
				"t:s"=>\$t,
				"cpu:s"=>\$cpu,
				"cut:s"=>\$cut,
				"lowq:s"=>\$lowq,
				"lowp:s"=>\$lowp,
				) or &USAGE;
&USAGE unless ($fIn and $fOut);
#my $queue="general.q";
#my $qsubcmd="sh /share/nas2/genome/bmksoft/tool/qsub_sge_plus/v1.0/qsub_sge.plus.sh";
my $hostname=`hostname`;chomp ($hostname);
mkdir $fOut unless(-d $fOut);
my $indir=ABSOLUTE_DIR($fIn);
my $outdir=ABSOLUTE_DIR($fOut);
$Run=$Run || 509;
$cpu=$cpu || 30;
$cut=$cut || 0;
$t=$t || 1;
my $Q;
if ($t==1) {
	$Q=33;
}elsif ($t==2) {
	$Q=64;
}else{
	print "please check your parameter of -t,it's wrong for Quality value!!!\n";die;
}
####################################################################################################ȷ��Q30��׼
open (CON,$config)or die;
my %Q30;my $qline;
my %hash;
while (<CON>) {
	next if (/^\s+/) ;
	if (/^Lane\#/) {
		my @line1=split /\t/,$_;
		Lable: for (my $i=0;$i<@line1;$i++) {
			if ($line1[$i]=~/Q30/) {
				$qline=$i;
				last Lable;
			}
		}
		next;
	}
	my @line=split /\t/,$_;
	my $sample="$line[2]"."_$line[3]";
	#print "$sample\n";
	my $cut=$line[-3];
	$hash{$sample}=$cut;
	if ($line[$qline]=~/\d+/) {
		$line[$qline]=~s/\%$//;
		$Q30{$sample}=$line[$qline]/100;
	}else{
		$Q30{$sample}=0.85;
	}
#	
}
########################################################################################################���˽�ͷ�͵�����
my $changedata="$outdir/changedata";mkdir "$changedata" unless (-d $changedata);
my $RawData="$outdir/first_cut";mkdir "$RawData" unless (-d $RawData);
my $adaData="$outdir/second_ada";mkdir "$adaData" unless (-d $adaData);
my $QuiltyData="$outdir/third_quilty";mkdir "$QuiltyData" unless (-d $QuiltyData);
my $duplication="$outdir/fouth_Dup";mkdir "$duplication" unless (-d $duplication);
my $fastqc="$outdir/fastqc";mkdir "$fastqc" unless (-d $fastqc);
my $work_sh="$outdir/work_sh";mkdir "$work_sh" unless (-d $work_sh);
open (Change,">$work_sh/change.sh") or die;
open (Cut_data,">$work_sh/cut.sh") or die;
open (Adapter,">$work_sh/ada.sh") or die;
open (Quality,">$work_sh/quality.sh") or die;
open (Ns,">$work_sh/Q.sh") or die;
open (QC,">$work_sh/QC.sh") or die;
open (FQ,">$work_sh/fastqc.sh") or die;
open (config_data,">$work_sh/dup.sh") or die;
open (Stat_data,">$work_sh/stats.sh") or die;


my $ss=0;
foreach my $file1 (glob ("$indir/*_1.fq")) {
	$file1=basename($file1);
	next if ($file1!~/-R\d+|D\d+|-E\d+|-M\d+|-X\d+|-C\d+|-H\d+|-J\d+|-V\d+/);
	my $file2=$file1;
	$file2=~s/_1.fq$/_2.fq/;
	my ($prefix)=basename($file1)=~/(.*)_1.fq/;
	unless (defined $Q30{$prefix}) {
			$Q30{$prefix}=0.85
	}

	$ss++;
	if (defined $hash{$prefix} && $hash{$prefix}=~/126/ ) {
		#print "$prefix\n";
		print Change "$Bin/bin/fastq_id_formatter -a $indir/$file1 -b $indir/$file2 -o $changedata -m HWI-7001455 -r $Run -f AC6BR9ANXX -p 3 \n";
	}
	else{
		$hash{$prefix}=151;
		print Change "$Bin/bin/fastq_id_formatter -a $indir/$file1 -b $indir/$file2 -o $changedata -m K00170 -r $Run -f AH3NTCBBXX -p 3 \n";
		}
	print Cut_data "perl $Bin/fastq_cut_by_cycle_list.pl -fq1 $changedata/$file1 -fq2 $changedata/$file2 -r1_start 1 -r2_start 1 -r1_cut_len $hash{$prefix} -r2_cut_len $hash{$prefix} -o1 $RawData/$file1 -o2 $RawData/$file2 \n";
	print Adapter "perl $Bin/bin/WipeAaapter.pl -i1 $RawData/$file1 -i2 $RawData/$file2 -w 0 -od $adaData -rec 13 -len 100 -cut $cut \n";
	print Quality "$Bin/bin/fastq_filter_by_multi_rules -a $adaData/$file1 -b $adaData/$file2 -c $QuiltyData/$prefix\_1.fq -d $QuiltyData/$prefix\_2.fq -u 0.1 -q $lowp -w $lowq -Q $Q \n";
	print Ns "$Bin/bin/fastq_filter_by_Qxx -a $QuiltyData/$file1 -b $QuiltyData/$file2 -q $Q30{$prefix} -w 30 -Q $Q -f $prefix -o $QuiltyData \n";
	print FQ "/share/nas2/genome/biosoft/FastQC/fastqc -o $fastqc -f fastq $QuiltyData/$prefix\_good_1.fq \n";
	print config_data "perl $Bin/bin/redetect_filt_v2.0.pl -f1 $QuiltyData/$prefix\_good_1.fq -f2 $QuiltyData/$prefix\_good_2.fq -k 17 -r 0.15 -od $duplication \n";

}
print QC "perl $Bin/bin/Data_Assess.pl 33 $QuiltyData $QuiltyData/Data_Assess ";
print Stat_data "perl $Bin/bin/Data_Assess.pl 33 $duplication $duplication/Data_Assess ";
close (Adapter);
close (Quality);
close (Stat_data);
close (Ns);
close (Change);
close (FQ);
close (config_data);


#############################################################
#system "/share/nas1/wangj/bin/Basecall/V_1.2/multi-process.pl $work_sh/ada.sh -cpu 10";
#system "/share/nas1/wangj/bin/Basecall/V_1.2/multi-process.pl $work_sh/Ns.sh -cpu 10";
#system "/share/nas1/wangj/bin/Basecall/V_1.2/multi-process.pl $work_sh/quality.sh -cpu 10";
#`sh $work_sh/stats.sh`;
#############################################################
	`sh  $work_sh/change.sh `;
	`sh  $work_sh/cut.sh `;
	`sh  $work_sh/ada.sh `;
	`sh  $work_sh/quality.sh `;
	`sh  $work_sh/Q.sh `;
	`sh  $work_sh/QC.sh `;
	`sh  $work_sh/fastqc.sh `;
	`sh  $work_sh/dup.sh `;
	`sh  $work_sh/stats.sh `;


##################################################################################################ͳ��reads�����ͽ�ͷ����
my %Total_stat;
my %adapter;
my %N;
foreach my $ada_file (glob ("$adaData/*_1.fq.xls")) {
	my ($sample)=basename($ada_file)=~/(\S+)_1.fq.xls/;
#	my $Ns_file="$RawData/$sample\_1.fq.Ns.fq";
#	my $Ns_data=`wc -l $Ns_file`;
#	$Ns_data=(split /\s+/,$Ns_data)[0];
	open (ADA,$ada_file) or die;
	while (<ADA>) {
		chomp;
		next if (/^$/);
		my @adapter=split /\s+/,$_;
		$Total_stat{$sample}{Total}=$adapter[1] if ($adapter[0]=~/Total_reads/) ;
		$adapter{$sample}=$adapter[1] if ($adapter[0]=~/Filter_reads/) ;
		
	}
	$Total_stat{$sample}{adapter}=sprintf("%.2f",$adapter{$sample}/$Total_stat{$sample}{Total}*100);
#	$N{$sample}=$Total_stat{$sample}{Total}-$adapter{$sample}-$Ns_data/4;
#	$Total_stat{$sample}{Ns}=sprintf("%.2f",$N{$sample}/$Total_stat{$sample}{Total});
}
##################################################################################################ͳ�Ƶ��������������ڷ���������
open (Quilty,"$QuiltyData/Data_Assess/AllSample_GC_Q.stat") or die;
while (<Quilty>) {
	chomp;
	next if (/^\#/ || /^$/ || /^SampleID/);
	my ($sample,$UseReads,$UseData,$UseGC,$UseQ20,$UseQ30)=(split /\t/,$_)[0,1,2,3,5,7];
	$UseData=$UseData/1000000000;
	$Total_stat{$sample}{filter}=$Total_stat{$sample}{Total}-$adapter{$sample}-$UseReads;
	$Total_stat{$sample}{inferior}=sprintf("%.2f",($Total_stat{$sample}{Total}-$adapter{$sample}-$UseReads)/$Total_stat{$sample}{Total}*100);
	$Total_stat{$sample}{Use}="$UseReads\t$UseData\t$UseGC\t$UseQ20\t$UseQ30";
}
close (Quilty);
##################################################################################################################ͳ��ȥ����֮�������
open (Dup,"$duplication/Data_Assess/AllSample_GC_Q.stat") or die;
while (<Dup>) {
	chomp;
	next if (/^\#/ || /^$/ || /^SampleID/);
	my ($sample1,$UseReads1,$UseData1,$UseGC1,$UseQ201,$UseQ301)=(split /\t/,$_)[0,1,2,3,5,7];
	$UseData1=$UseData1/1000000000;
	$Total_stat{$sample1}{dup}=sprintf("%.2f",($Total_stat{$sample1}{Total}-$adapter{$sample1}-$Total_stat{$sample1}{filter}-$UseReads1)/$Total_stat{$sample1}{Total}*100);
	$Total_stat{$sample1}{Use1}="$UseReads1\t$UseData1\t$UseGC1\t$UseQ201\t$UseQ301";
}
close (Quilty);

###################################################################################################���ͳ�ƽ��
open (STAT,">$outdir/All_sample_stat.xls") or die;
print STAT "#Sample\tTotal_Read\tAdapter_percent\tInferior_percent\tDup(%)\tUseRead\tUseData(G)\tUseGC\tUseQ20\tUseQ30\n";
foreach my $sample (keys %Total_stat) {
	print STAT "$sample\t$Total_stat{$sample}{Total}\t$Total_stat{$sample}{adapter}\t";
	print STAT "$Total_stat{$sample}{inferior}\t$Total_stat{$sample}{dup}\t$Total_stat{$sample}{Use}\n";
}
close (STAT);

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------
################################################################################################################

sub ABSOLUTE_DIR{ #$pavfile=&ABSOLUTE_DIR($pavfile);
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir\n";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

################################################################################################################

sub max{#&max(lists or arry);
	#���б��е�����?
	my $max=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$max=$max>$temp?$max:$temp;
	}
	return $max;
}

################################################################################################################

sub min{#&min(lists or arry);
	#���б��е���Сֵ
	my $min=shift;
	my $temp;
	while (@_) {
		$temp=shift;
		$min=$min<$temp?$min:$temp;
	}
	return $min;
}

################################################################################################################

sub revcom(){#&revcom($ref_seq);
	#��ȡ�ַ������еķ��򻥲����У����ַ�����ʽ���ء�ATTCCC->GGGAAT
	my $seq=shift;
	$seq=~tr/ATCGatcg/TAGCtagc/;
	$seq=reverse $seq;
	return uc $seq;			  
}

################################################################################################################

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}


sub USAGE {#
	my $usage=<<"USAGE";
ProgramName: DNA_Rawdata_filter
Version:	$version
Contact:	wangjing <wangj\@biomarker.com.cn> 
Program Date: 2014-7-17
Modify:           ##move adapter recongnize programs to my bin dir
Description:	this program is used to filter DNA iterms\'s adapter and inferior quality 
Usage:
  Options:
	-i		Raw_data dir 	forced

	-config	config file		forced

	-o		outdir	forced

	-Run		Run number default 509

	-t		the type of quality encode ( 1:33; 2:64; ) [default 1]

	-cpu	proess number default 30

	-cut	�г�read1ǰ3bp,1��0,0���У�Ĭ��Ϊ0

	-lowp    percent cutoff of low quality
	-lowq    low quality cutoff


  -h         Help

USAGE
	print $usage;
	exit;
}
