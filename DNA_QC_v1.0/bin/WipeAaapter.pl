#!/usr/bin/perl -w
use strict;
use warnings;
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
my ($fq1,$fq2,$od,$wrong,$rec_len,$seq_len,$num);
GetOptions(
				"help|?" =>\&USAGE,
				"i1:s"=>\$fq1,
				"i2:s"=>\$fq2,
				"rec:s"=>\$rec_len,
				"w:s"=>\$wrong,
				"od:s"=>\$od,
				"cut:s"=>\$num,
				"len:s"=>\$seq_len,
				) or &USAGE;
&USAGE unless ($fq1 and $fq2 and $od and $rec_len );
#######################################################################################
# ------------------------------------------------------------------
# Main Body
#my $BEGIN_TIME=time();
my $Time_Start = &sub_format_datetime(localtime($BEGIN_TIME));
print "Program Starts Time:$Time_Start\n";
# ------------------------------------------------------------------

my $adpter3="AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC";

my $adpter5="AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT";
$fq2=&ABSOLUTE_DIR($fq2);
$fq1=&ABSOLUTE_DIR($fq1);

mkdir $od if(!-d $od);
$od=&ABSOLUTE_DIR($od);

my $filter1=0;
my $Total_reads=0;

my $name1=basename($fq1);
my $name2 =basename($fq2);

$wrong||=0;
$seq_len||=60;
$num||=0;

my %hash=(	
	"AAAAAAAAAAAAAAAAAA"=>10,
	"GCTCTTCCGATC"=>9,
);
my %tmp=(	
	"AAAAAAAAAAAAAAAAA"=>10,
	"GCTCTTCCGATC"=>9,
) ;

my %matrix;
my %del;

my $rec_adpter3=substr($adpter3,0,$rec_len);
my $rec_adpter5=substr($adpter5,0,$rec_len);

foreach my $num (5..$rec_len-1) {
	my $fq1_adapter3=substr($adpter3,0,$num);
	my $fq2_adapter5=substr($adpter5,0,$num);
	$del{3}{$fq1_adapter3}=0;
	$del{5}{$fq2_adapter5}=0;
}

$matrix{3}{0}{$rec_adpter3}=0;
$matrix{5}{0}{$rec_adpter5}=0;

if($wrong!=0){
	foreach my $key (sort{$a<=>$b} keys %matrix) {
		my $next_wrong_num=0;
		foreach my $w (0..$wrong-1) 
		{
			$next_wrong_num++;
			foreach my $seq (keys %{$matrix{$key}{$w}}) 
			{
				my @base=split //,$seq;
				my $count=0;
				foreach my $bb (@base) 
				{
					if ($bb ne "\.") 
					{
						my @wrong_base=@base;
						$wrong_base[$count]=".";
						my $wrong_adapter=join "",@wrong_base;
						$matrix{$key}{$next_wrong_num}{$wrong_adapter}=0;
					}
					$count++;
				}
			}
		}
	}
}
open STAT,">$od/$name1.xls"||die $!;
open (FQ1,"<",$fq1) or die $!;
open (FQ2,"<",$fq2) or die $!;
open (Clean1,">","$od/$name1") or die $!;
open (Clean2,">","$od/$name2") or die $!;
open (Adpter31,">","$od/$name1.adpter3") or die $!;
open (Adpter32,">","$od/$name2.adpter3") or die $!;
open (Adpter51,">","$od/$name1.adpter5") or die $!;
open (Adpter52,">","$od/$name2.adpter5") or die $!;
while (my $r1_line1=<FQ1>) {
	chomp ($r1_line1);
	$Total_reads++;
	my $r1_line2=<FQ1>;	chomp($r1_line2);
	my $r1_line3=<FQ1>;	chomp($r1_line3);
	my $r1_line4=<FQ1>; chomp($r1_line4);
	my $r2_line1=<FQ2>; chomp($r2_line1);
	my $r2_line2=<FQ2>; chomp($r2_line2);
	my $r2_line3=<FQ2>; chomp($r2_line3);
	my $r2_line4=<FQ2>; chomp($r2_line4);
	my $len_seq1=length ($r1_line2);
	my $len_q1=length ($r1_line4);
	my $len_seq2=length ($r2_line2);
	my $len_q2=length ($r2_line4);
	if ($len_seq1 ne $len_q1 or $len_seq2 ne $len_q2 ) {
		next;
	}
	else{
		if($num==1){
			$r1_line2=substr($r1_line2,3);
			$r1_line4=substr($r1_line4,3);

		}
		my $cyc=0;
		my $c1=0;
		my $c2=0;
	
		my $cyc1=0;
		my $cyc2=0;
	
		if ($r1_line2=~/CTGAACTCCAGTCAC/ && $cyc==0){
			my $pos=index($r1_line2,"CTGAACTCCAGTCAC");
			if ($pos-19<$seq_len){
				$cyc++;
				print Adpter31 "$r1_line1\n";
					 print Adpter31 "$r1_line2\n";
                        print Adpter31 "$r1_line3\n";
                        print Adpter31 "$r1_line4\n";
                        print Adpter32 "$r2_line1\n";
                        print Adpter32 "$r2_line2\n";
                        print Adpter32 "$r2_line3\n";
                        print Adpter32 "$r2_line4\n";
                       $filter1++;
			}else{
				$r1_line2=&trim($r1_line2,$pos-19);			
				$r1_line4=&trim($r1_line4,$pos-19);
				$r2_line2=&trim($r2_line2,$pos-19);
				$r2_line4=&trim($r2_line4,$pos-19);
			}
		}
	if ($r2_line2=~/TAGGGAAAGAGTGT/ && $cyc==0){
                my $pos=index($r2_line2,"TAGGGAAAGAGTGT");
                if ($pos-19<$seq_len){
                        $cyc++;
                        print Adpter51 "$r1_line1\n";
                        print Adpter51 "$r1_line2\n";
                        print Adpter51 "$r1_line3\n";
                        print Adpter51 "$r1_line4\n";
                        print Adpter52 "$r2_line1\n";
                        print Adpter52 "$r2_line2\n";
                        print Adpter52 "$r2_line3\n";
                        print Adpter52 "$r2_line4\n";
                        $filter1++;
                }else{
                        $r2_line2=&trim($r2_line2,$pos-19);
                        $r2_line4=&trim($r2_line4,$pos-19);
                        $r1_line2=&trim($r1_line2,$pos-19);
                        $r1_line4=&trim($r1_line4,$pos-19);
                }
        }

	 Lable1: foreach  my $adp (sort {$a cmp $b}keys %{$del{3}}) {
		  last Lable1 if($cyc!=0);
		if($r1_line2=~/$adp$/){
			$r1_line2=&cut($r1_line2,$adp);
			$r1_line4=&cut($r1_line4,$adp);
			$r2_line2=&cut($r2_line2,$adp);
			$r2_line4=&cut($r2_line4,$adp);
			$c1++;
		}

		last Lable1 if($c1!=0);
	}
	Lable2: foreach my $adp (sort {$a cmp $b}keys %{$del{5}}) {
		last Lable2 if($cyc!=0);
		if($r2_line2=~/$adp$/){
			$r2_line2=&cut($r2_line2,$adp);
			$r2_line4=&cut($r2_line4,$adp);
			$r1_line2=&cut($r1_line2,$adp);
			$r1_line4=&cut($r1_line4,$adp);
			$c2++;			
		}
		last Lable2 if($c2!=0);
	}


	Lables1: foreach  my $num(sort{$a<=>$b}keys %{$matrix{3}}) {
				  last Lables1 if($cyc!=0);
		 foreach my $adapter3 (keys %{$matrix{3}{$num}}) {
			  
			
			if($r1_line2=~/$adapter3/){
				my $pos=index($r1_line2,$adapter3);
				if($pos<$seq_len){
					
					$cyc++;
					print Adpter31 "$r1_line1\n";
					print Adpter31 "$r1_line2\n";
					print Adpter31 "$r1_line3\n";
					print Adpter31 "$r1_line4\n";
					print Adpter32 "$r2_line1\n";
					print Adpter32 "$r2_line2\n";
					print Adpter32 "$r2_line3\n";
					print Adpter32 "$r2_line4\n"; 
					$filter1++;
				
				}else{
					$r1_line2=&trim($r1_line2,$pos);			
					$r1_line4=&trim($r1_line4,$pos);
					$r2_line2=&trim($r2_line2,$pos);
					$r2_line4=&trim($r2_line4,$pos);
					$cyc1++;
					last Lables1 if($cyc1!=0);
				
				}
			
			
		
			}
		}
	}
	Lables2: foreach my $num (sort {$a<=>$b}keys %{$matrix{5}}) {
		last Lables2 if($cyc!=0);
		foreach my $adapter5 (keys %{$matrix{5}{$num}}) {
			 last Lables2 if($cyc!=0);
			 last Lables2 if($cyc2!=0);
			if($r2_line2=~/$adapter5/){
				my $pos=index($r2_line2,$adapter5);
				if($pos<$seq_len){
					$cyc++;
					print Adpter51 "$r1_line1\n";
					print Adpter51 "$r1_line2\n";
					print Adpter51 "$r1_line3\n";
					print Adpter51 "$r1_line4\n";
					print Adpter52 "$r2_line1\n";
					print Adpter52 "$r2_line2\n";
					print Adpter52 "$r2_line3\n";
					print Adpter52 "$r2_line4\n";
					$filter1++;
					last Lables2 if($cyc!=0);
				}else{
					$r2_line2=&trim($r2_line2,$pos);
					$r2_line4=&trim($r2_line4,$pos);
					$r1_line2=&trim($r1_line2,$pos);
					$r1_line4=&trim($r1_line4,$pos);
					$cyc2++;
					last Lables2 if($cyc2!=0);
					
				}
				
				
			}
		}
	}
	Lab1:foreach my $key (sort {$hash{$b}<=>$hash{$a}}keys %hash) {
		last Lab1 if($cyc!=0);
		if($r1_line2=~/$key/){
			$cyc++;
			print Adpter31 "$r1_line1\n";
			print Adpter31 "$r1_line2\n";
			print Adpter31 "$r1_line3\n";
			print Adpter31 "$r1_line4\n";
			print Adpter32 "$r2_line1\n";
			print Adpter32 "$r2_line2\n";
			print Adpter32 "$r2_line3\n";
			print Adpter32 "$r2_line4\n"; 
			$filter1++;
			last Lab1 if($cyc!=0);
			
		
		}
	}
	Lab2:foreach my $key (sort {$tmp{$b}<=>$tmp{$a}}keys %tmp) {
		last Lab2 if($cyc!=0);
		if($r2_line2=~/$key/){
			$cyc++;
			print Adpter51 "$r1_line1\n";
			print Adpter51 "$r1_line2\n";
			print Adpter51 "$r1_line3\n";
			print Adpter51 "$r1_line4\n";
			print Adpter52 "$r2_line1\n";
			print Adpter52 "$r2_line2\n";
			print Adpter52 "$r2_line3\n";
			print Adpter52 "$r2_line4\n";
			$filter1++;
			last Lab2 if($cyc!=0);
		
		
		}
	}
	if($cyc==0){
	
		print Clean1 "$r1_line1\n";
		print Clean1 "$r1_line2\n";
		print Clean1 "$r1_line3\n";
		print Clean1 "$r1_line4\n";
		print Clean2 "$r2_line1\n";
		print Clean2 "$r2_line2\n";
		print Clean2 "$r2_line3\n";
		print Clean2 "$r2_line4\n";
		}
	}
}
close (FQ1) ;
close (FQ2) ;

print STAT"Total_reads\t$Total_reads\nFilter_reads\t$filter1\n";




#######################################################################################
my $Time_End   = sub_format_datetime(localtime(time()));
print STDOUT "Program Ends Time:$Time_End\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
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
###############################################################################################
sub cut{
	my ($seq,$adapter1)=@_;
	my $ad_len=length $adapter1;
	my $return=substr($seq,0,-$ad_len);
	return $return;

}
##############################################################################################
sub trim{
	my ($str,$position)=@_;
	my $return=substr($str,0,$position-1);
	return $return;
	
}

################################################################################################

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
#################################################################################################

sub sub_format_datetime {#Time calculation subroutine
	my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
	sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
#########################################################################################

sub USAGE {#
	my $usage=<<"USAGE";
Program:
Version: $version
Contact: guoxc <guoxc\@biomarker.com.cn> 
Description:

Usage:
  Options:
	-i1	<infile>	input file, fq1 file
	-i2	<infile>	input file, fq2 file
	-w  <int>		adapter Fault-tolerant rate ,default 0
	-od	<dir>	output file directory, forced  不要和输入文件目录一致
	-rec <int>	Recognize adapter length forced
	-len <int>	  the min leng of reads,default 60;	
	-cut <int>  切掉read1前3bp，1切 0 不切 默认为 0
	-h				Help

USAGE
	print $usage;
	exit;
}
