#!/usr/bin/perl -w
# Copyright (c) BIO_MARK 2011
# Writer:         Dengdj <dengdj@biomarker.com.cn>
# Program Date:   2011
# Modifier:       Dengdj <dengdj@biomarker.com.cn>
# Last Modified:  2011.
my $ver="2.0";


use strict;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

######################请在写程序之前，一定写明时间、程序用途、参数说明；每次修改程序时，也请做好注释工作

my %opts;
GetOptions(\%opts,"f1=s@","f2=s@","od=s","k=s","r=s","h" );

#&help()if(defined $opts{h});
if(!defined($opts{f1}) || !defined($opts{f2}) || !defined($opts{od}) || defined($opts{h}))
{
	print <<"End." ;
	 Name

	 redetect_filt.pl  --filtered for duplicates.

	 Description

	 This program write for filt PCR duplicates PE reads.

	 Version

	 Writer: Dengdj <dengdj\@biomarker.com.cn>
	 Version: $ver,  Date: 2011-12-01
	          v2.0:  filter some duplication reads

	 Usage

	 perl redetect_filt.pl 
	 -f1 infq files 1
	 -f2 infq files 2
	 -od outdir
	 -k  kmer size
	 -r  maximum duplication ratio
	 -h output help information to screen  

	 Exmple

	 perl redetect_filt.pl -f1 file1.fq -f2 file2.fq [-f1 newfile1.fq -f2 newfile2.fq ...] -od outdir [-k 17] [-r 0.1]

End.
	exit (1) ;
}

###############Time
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";
################

my $infile1  = $opts{f1} ;
my $infile2  = $opts{f2} ;
my $outdir = $opts{od} ;
my $kmer = defined $opts{k} ? $opts{k} : 17 ;
my $ratio = defined $opts{r} ? $opts{r} : 0.1 ;
$ratio = 1 if ($ratio > 1) ;
$ratio = 0 if ($ratio < 0) ;

mkdir $outdir if (!-d $outdir) ;

if (scalar @$infile1 != scalar @$infile2){
	print "fq1 files number must equal to fq2 files !\n" ;
	exit ;
}
my %hseq = () ;
for (my $i=0; $i<@$infile1; $i++){
	open (IN1, "$$infile1[$i]") || die "Can't open $$infile1[$i], $!\n" ;
	open (IN2, "$$infile2[$i]") || die "Can't open $$infile2[$i], $!\n" ;
	my $out1 = basename $$infile1[$i] ;
	my $out2 = basename $$infile2[$i] ;
	open (OUT, ">$outdir/$out1.xls") || die "Can't creat $outdir/$out1.xls, $!\n" ;
	open (REP1, ">$outdir/$out1.rep") || die "Can't creat $outdir/$out1.rep, $!\n" ;
	open (REP2, ">$outdir/$out2.rep") || die "Can't creat $outdir/$out2.rep, $!\n" ;
	open (NOR1, ">$outdir/$out1") || die "Can't creat $outdir/$out1, $!\n" ;
	open (NOR2, ">$outdir/$out2") || die "Can't creat $outdir/$out2, $!\n" ;
	my $rep_count = 0 ;
	my $total_count = 0 ;
	my $total=0;
	my $rep=0;
	while(<IN1>){
		chomp ;
		my $id1 = $_ ;
		my $seq1 = <IN1> ;
		my $_id1 = <IN1> ;
		my $qua1 = <IN1> ;
		$total++;
		my $id2 = <IN2> ;
		my $seq2 = <IN2> ;
		my $_id2 = <IN2> ;
		my $qua2 = <IN2> ;

		chomp ($id1, $id2, $seq1, $seq2, $_id1, $_id2, $qua1, $qua2) ;

		my $fir_sub_seq = substr ($seq1, 0, $kmer) ;
		my $sec_sub_seq = substr ($seq2, 0, $kmer) ;

		if (!defined $hseq{$fir_sub_seq}->{$sec_sub_seq}){
			$total_count++ ;
			print NOR1 "$id1\n$seq1\n$_id1\n$qua1\n" ;
			print NOR2 "$id2\n$seq2\n$_id2\n$qua2\n" ;
			$hseq{$fir_sub_seq}->{$sec_sub_seq} = 1 ;
		}
		else{
			$rep++;
			$rep_count++ ;
			$total_count++ ;
			if ($rep_count/$total_count > $ratio){
				print REP1 "$id1\n$seq1\n$_id1\n$qua1\n" ;
				print REP2 "$id2\n$seq2\n$_id2\n$qua2\n" ;
				$rep_count -- ;
				$total_count -- ;
			}
			else{
				print NOR1 "$id1\n$seq1\n$_id1\n$qua1\n" ;
				print NOR2 "$id2\n$seq2\n$_id2\n$qua2\n" ;
			}
		}
	}
	print OUT "Dup_Reads\t$rep\nTotal_Reads\t$total\n";

	close(IN1) ;
	close(IN2) ;
	close(REP1) ;
	close(REP2) ;
	close(NOR1) ;
	close(NOR2) ;
}
#for (my $i=0; $i<@$infile1; $i++){
#	open (IN1, "$$infile1[$i]") || die "Can't open $$infile1[$i], $!\n" ;
#	open (IN2, "$$infile2[$i]") || die "Can't open $$infile2[$i], $!\n" ;
#	my $out1 = basename $$infile1[$i] ;
#	my $out2 = basename $$infile2[$i] ;
#	open (REP1, ">$outdir/rep_$out1") || die "Can't creat $outdir/rep_$out1, $!\n" ;
#	open (REP2, ">$outdir/rep_$out2") || die "Can't creat $outdir/rep_$out2, $!\n" ;
#	open (NOR1, ">$outdir/nor_$out1") || die "Can't creat $outdir/nor_$out1, $!\n" ;
#	open (NOR2, ">$outdir/nor_$out2") || die "Can't creat $outdir/nor_$out2, $!\n" ;
#	while(<IN1>){
#		my $id1 = $_ ;
#		my $seq1 = <IN1> ;
#		my $_id1 = <IN1> ;
#		my $qua1 = <IN1> ;
#		chomp ($id1, $seq1, $_id1, $qua1) ;
#
#		my $id2 = <IN2> ;
#		my $seq2 = <IN2> ;
#		my $_id2 = <IN2> ;
#		my $qua2 = <IN2> ;
#		chomp ($id2, $seq2, $_id2, $qua2) ;
#
#		if ($hseq{$seq1}->{$seq2} > 1){
#			print REP1 "$id1\n$seq1\n$_id1\n$qua1\n" ;
#			print REP2 "$id2\n$seq2\n$_id2\n$qua2\n" ;
#		}
#		else {
#			print NOR1 "$id1\n$seq1\n$_id1\n$qua1\n" ;
#			print NOR2 "$id2\n$seq2\n$_id2\n$qua2\n" ;
#		}
#	}
#	close(IN1) ;
#	close(IN2) ;
#	close(REP1) ;
#	close(REP2) ;
#	close(NOR1) ;
#	close(NOR2) ;
#}

###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd Time :[$Time_End]\n\n";

###############Subs
sub sub_format_datetime {#Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub ABSOLUTE_DIR
{ #$pavfile=&ABSOLUTE_DIR($pavfile);
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
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
