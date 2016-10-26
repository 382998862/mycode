#!usr/bin/perl -w
use strict;
use Getopt::Long;
my $ver= "1.0";


my %opts;
GetOptions(\%opts, "i=s", "od=s", "p=s", "bed=s","d=i","h");
if(!defined($opts{i}) ||!defined($opts{od}) ||!defined($opts{p}) ||!defined($opts{bed}) ||!defined($opts{d}) || defined($opts{h}))
{
	print << " 	Usage End.";
	Description:
		Version:$ver
		Date: 2014-10-31
		This is a script for summraizing 
		Fastq and Bam file quality control
	Author:
		Ma Chengcheng
	Usage:
		-i 	input bam file 		(required)
		-od 	output dir 		(required)
		-p 	output prefix 		(required)
		-bed 	bed file of regions 	(required)
		-d 	designed depth 		(required)
 	Usage End.
	exit;
}
my $depth = $opts{d};
my $bed = $opts{bed};
my $dir = $opts{od};
my $prefix = $opts{p};
my $bam = $opts{i};
my $bed_dir= "/share/nas2/genome/biosoft/bedtools2/current/bin/";

open(FASTQC, "$dir/../FastQC/$prefix.stat") || die "no FASTQC!!";
open(BED, $bed)||die "can not open bed file";
my $outdir = "$dir/Summary";
mkdir $outdir;
open(OUT, ">$outdir/$prefix.summary.txt") || die "cannot creat summary";
my $reads =0;
my @MAQ;
my $lengthmaq;
my @MAQ20;
while(<FASTQC>){
	chomp;
	my @line = split (/\t/, $_);
	if ($line[1] =~ /^\d+$/){
		$reads = $reads + $line[1];
	}
	my $line = join("\t", @line[1..6]);
	print OUT $line,"\n";
}
print OUT "Number of reads: ", $reads,"\n";

### Calculate MAQ20
@MAQ = `samtools view -F 4 $bam| awk '{print \$5}'`;
$lengthmaq = @MAQ;
print OUT "Number of mapped reads: ", $lengthmaq,"\t";
printf OUT "%0.2f%\n",$lengthmaq/$reads*100;
foreach my $maq (@MAQ){
	if ($maq > 20){
		push(@MAQ20, $maq);
	}
}
my $maq20 = @MAQ20;
print OUT "Number of MAQ20: ",$maq20,"\t"; 
printf OUT "%0.2f%\n",$maq20/$lengthmaq*100;
close OUT;
#### Get Mean depth in the region
system("$bed_dir/bedtools bamtobed -i $bam > $outdir/$prefix.bed");
print "BAM to BED done\n";
system("$bed_dir/bedtools coverage -a $outdir/$prefix.bed -b $bed > $outdir/$prefix.region.txt");
system("$bed_dir/bedtools coverage -b $outdir/$prefix.bed -a $bed > $outdir/region.$prefix.txt");
print "Interset BED files done\n";

system("awk 'BEGIN {sum=0} {sum=sum+\$7} END {print \"Mean depth:\", sum/NR}' $outdir/$prefix.region.txt >>$outdir/$prefix.summary.txt");
system("awk 'BEGIN {count=0;} {if(\$7 > \$depth/5){count = count+1;}} END {printf \"Uniformity: \%0.2f\%\\n\",(count-1)/NR*100}' $outdir/$prefix.region.txt >>$outdir/$prefix.summary.txt");
system("awk 'BEGIN {count=0;} {if(\$10 > 0){count = count+1;}} END {printf \"On target: \%d\\t\%0.2f\%\\n\",(count-1),(count-1)/NR*100}' $outdir/region.$prefix.txt >>$outdir/$prefix.summary.txt");
close FASTQC;
close BAM;
close DEPTH;
close BED;

