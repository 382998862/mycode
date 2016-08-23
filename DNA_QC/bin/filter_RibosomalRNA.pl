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
my ($a,$b,$Q,$All,$Pe,$fOut);
GetOptions(
				"help|?" =>\&USAGE,
				"a:s"=>\$a,
				"b:s"=>\$b,
				"Q:s"=>\$Q,
				"All"=>\$All,
				"Pe"=>\$Pe,
				"od:s"=>\$fOut,
				) or &USAGE;
&USAGE unless ($a and $b and $fOut);

if (((defined $All) && (defined $Pe)) || ((!defined $All) && (!defined $Pe))) {
	print "\nPlease choose one from All and Pe!\n";
	die;
}
$Q||=33;
$a=&ABSOLUTE_DIR($a);
$b=&ABSOLUTE_DIR($b);
my $name_a=basename $a;
my $name_b=basename $b;
my $index=$name_a;


my $pe=$index.'out.pe';
my $se=$index.'out.se';
my $fa=$index.'unmap.fa';


`mkdir $fOut` unless -d $fOut;
chdir $fOut;
`/share/nas2/genome/biosoft/soap/current/soap -a $a -b $b -D /share/nas36/database/sRNA_database/current/ncRNA_integer.fasta.index -o $pe -2 $se -m 100 -x 1000 -u $fa`;
my %hash;
my $unmap=0;
my $total=0;
$/=">";
open (IN,$fa) or die $!;
while (<IN>) {
	chomp;
	next if /^$/;
	my @A;
	@A=split/\s+/,$_ if $Q==33;
	@A=(split/\s+/,$_)[0]=~/(.+)\/(\d)$/ if $Q==64;
	$hash{$A[0]}=2 if exists $hash{$A[0]};
	$hash{$A[0]}=1 unless exists $hash{$A[0]};
}
close IN;
$/="\n";
if (defined $Pe) {
	open (IN,$se) or die $!;
	while (<IN>) {
		chomp;
		next if /^$/;
		my @A;
		@A=split/\s+/,$_ if $Q==33;
		@A=(split/\s+/,$_)[0]=~/(.+)\/(\d)$/ if $Q==64;
		$hash{$A[0]}=1;
	}
	close IN;
	open (IN,$a) or die $!;
	open (OUT,">$name_a") or die $!;
	while (<IN>) {
		$total++;
		my @B;
		@B=split/\s+/,$_ if $Q==33;
		@B=(split/\s+/,$_)[0]=~/(.+)\/(\d)$/ if $Q==64;
		$B[0]=~s/^\@//;
		if (exists $hash{$B[0]}) {
			print OUT $_;
			my $x=<IN>;
			print OUT $x;
			my $y=<IN>;
			print OUT $y;
			my $z=<IN>;
			print OUT $z;
		}
		else{
			<IN>;
			<IN>;
			<IN>;
		}
	}
	close IN;
	close OUT;
	open (IN,$b) or die $!;
	open (OUT,">$name_b") or die $!;
	while (<IN>) {
		my @B;
		@B=split/\s+/,$_ if $Q==33;
		@B=(split/\s+/,$_)[0]=~/(.+)\/(\d)$/ if $Q==64;
		$B[0]=~s/^\@//;
		if (exists $hash{$B[0]}) {
			print OUT $_;
			print OUT scalar <IN>;
			print OUT scalar <IN>;
			print OUT scalar <IN>;
		}
		else{
			<IN>;
			<IN>;
			<IN>;
		}
	}
	close IN;
	close OUT;
	$unmap=keys %hash;
	my $unmap_percent=$unmap/$total*100;
	$unmap_percent=sprintf "%.2f",$unmap_percent;
	my $stat=$index."stat.txt";
	open (OUT,">$stat");
	print OUT "Total_number\tunmap_number\tunmap_percent\n";
	print OUT "$total\t$unmap\t$unmap_percent".'%'."\n";
	close OUT;
}
if (defined $All) {
	open (IN,$a) or die $!;
	open (OUT,">$name_a") or die $!;
	while (<IN>) {
		$total++;
		my @B;
		@B=split/\s+/,$_ if $Q==33;
		@B=(split/\s+/,$_)[0]=~/(.+)\/(\d)$/ if $Q==64;
		$B[0]=~s/^\@//;
		if (exists $hash{$B[0]} && $hash{$B[0]}==2) {
			$unmap++;
			print OUT $_;
			my $x=<IN>;
			print OUT $x;
			my $y=<IN>;
			print OUT $y;
			my $z=<IN>;
			print OUT $z;
		}
		else{
			<IN>;
			<IN>;
			<IN>;
		}
	}
	close IN;
	close OUT;
	open (IN,$b) or die $!;
	open (OUT,">$name_b") or die $!;
	while (<IN>) {
		my @B;
		@B=split/\s+/,$_ if $Q==33;
		@B=(split/\s+/,$_)[0]=~/(.+)\/(\d)$/ if $Q==64;
		$B[0]=~s/^\@//;
		if (exists $hash{$B[0]} && $hash{$B[0]}==2) {
			print OUT $_;
			print OUT scalar <IN>;
			print OUT scalar <IN>;
			print OUT scalar <IN>;
		}
		else{
			<IN>;
			<IN>;
			<IN>;
		}
	}
	close IN;
	close OUT;
	my $unmap_percent=$unmap/$total*100;
	$unmap_percent=sprintf "%.2f",$unmap_percent;
	my $stat=$index."stat.txt";
	open (OUT,">$stat");
	print OUT "Total_number\tunmap_number\tunmap_percent\n";
	print OUT "$total\t$unmap\t$unmap_percent".'%'."\n";
	close OUT;
}




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
	#求列表中的最大值
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
	#求列表中的最小值
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
	#获取字符串序列的反向互补序列，以字符串形式返回。ATTCCC->GGGAAT
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
ProgramName:
Version:	$version
Contact:	Zhang XueChuan <zhangxc\@biomarker.com.cn> 
Program Date:   2012.8.23
Description:	this program is used to filter RibosomalRNA.
Usage:
  Options:
  -a <file>  input file,fastq format,forced 
  
  -b <file>  input file,fastq format,forced 
  
  -Q <num>   Quality Value,33 or 64,default 33
  
  -All  
  
     -Pe  
  
  -od <file>  output dir,forced 

  -h         Help

USAGE
	print $usage;
	exit;
}
