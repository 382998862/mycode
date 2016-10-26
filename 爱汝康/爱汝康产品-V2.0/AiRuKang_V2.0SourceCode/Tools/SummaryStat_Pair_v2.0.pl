use strict;
use File::Basename;
use Getopt::Long;
my $ver= "1.0";


my %opts;
GetOptions(\%opts, "i=s", "od=s", "p=s", "bed=s","d=i","r=s", "ct=s","h");
if(!defined($opts{i}) ||!defined($opts{od}) ||!defined($opts{p}) ||!defined($opts{bed}) ||!defined($opts{r}) ||!defined($opts{d}) || defined($opts{h}))
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
		-i			input bam file			(required)
		-od			output dir			(required)
		-p			output prefix			(required)
		-bed			bed file of regions		(required)
		-d			designed depth			(required)
		-r			reference			(required)
		-ct			summaryCoverageThreshold	(optional)
 	Usage End.
	exit;
}
my $depth = $opts{d};
my $bed = $opts{bed};
my $dir = $opts{od};
my $prefix = $opts{p};
my $bam = $opts{i};
my $CovThr = $opts{ct};
my $gatk_dir="/share/nas2/genome/biosoft/GATK/3.0-0/" ;  ##### 20160603

#my $java_dir="/share/nas1/dengdj/bin/Bio_soft/jre1.7.0_45/bin" ;  ##### none
#my $bed_dir="/share/nas2/genome/biosoft/bedtools2/current/bin";   ##### none!!!
my $ref = $opts{r};
#print $dir;
#print dirname($dir),"\n";
my $f1 = dirname(dirname($dir))."/FastQC/$prefix.stat";
#my $f2 = dirname(dirname($dir))."/FastQC/$prefix-2.stat";
print $f1,"\n";
#print $f2, "\n";

#open(FASTQC_1, $f1) || die "no FASTQC1!!";
#open(FASTQC_2, $f2) || die "no FASTQC2!!";
open(FASTQC, $f1) || die "no FASTQC!!";
print $bed,"\n";
open(BED, $bed)||die "can not open bed file";
my $outdir = "$dir";
mkdir $outdir;
open(OUT, ">$outdir/$prefix.summary.txt") || die "cannot creat summary";
my $reads_1;
my $reads_2;
my @MAQ;
my $lengthmaq;
my @MAQ20;
while(<FASTQC>){
	chomp;
	my @line = split (/\t/, $_);
	if ($line[0] == "read_A"){
		$reads_1 = $line[1];
	}
	if ($line[0] == "read_B"){
		$reads_2 = $line[1];
	}
	my $line = join("\t", @line[1..7]);
	print OUT $line,"\n";
}
print OUT "Number of reads in FASTQ: ", $reads_1+$reads_2,"\n";
print OUT "\n";

#while(<FASTQC_2>){
#	chomp;
#	my @line = split (/\t/, $_);
#	if ($line[1] =~ /^\d+$/){
#		$reads_2 = $line[1];
#	}
#	my $line = join("\t", @line[1..7]);
#	print OUT $line,"\n";
#}
#print OUT "Number of reads in FASTQ_2: ", $reads_2,"\n";
#print OUT "\n";
### Calculate MAQ20
@MAQ = `samtools view -F 4 $bam| awk '{print \$5}'`;
$lengthmaq = @MAQ;
print OUT "Number of mapped reads: ", $lengthmaq,"\t";
printf OUT "%0.2f%\n",$lengthmaq/($reads_1 + $reads_2)*100;
foreach my $maq (@MAQ){
	if ($maq > 20){
		push(@MAQ20, $maq);
	}
}
my $maq20 = @MAQ20;
print OUT "Number of MAQ20: ",$maq20,"\t"; 
printf OUT "%0.2f%\n",$maq20/$lengthmaq*100;

#### Get Mean depth in the region
#system("$bed_dir/bedtools bamtobed -i $bam > $outdir/$prefix.bed");
#print "BAM to BED done\n";
#system("java -jar $gatk_dir/GenomeAnalysisTK.jar -T DepthOfCoverage -I $bam -o $outdir/$prefix.dep -L $bed -R $ref -omitBaseOutput -omitLocusTable --summaryCoverageThreshold 1")   ;
system("java -jar $gatk_dir/GenomeAnalysisTK.jar -T DepthOfCoverage -I $bam -o $outdir/$prefix.dep -L $bed -R $ref -omitBaseOutput -omitLocusTable -rf BadCigar --summaryCoverageThreshold $CovThr");   ### 20160510 change to 20  20160615 -rf BadCigar
#system("$bed_dir/bedtools coverage -b $outdir/$prefix.bed -a $bam > $outdir/region.$prefix.txt");
my $dep_file = "$outdir/$prefix.dep.sample_summary";
my $uni_file = "$outdir/$prefix.dep.sample_interval_summary";
my $on_target = `samtools view -F 4 -c $bam -L $bed`;
my @dep;
my $depth_avg;
my $coverage_avg;

open (DEP, $dep_file);
<DEP>;
@dep = split(/\s+/, <DEP>);
$depth_avg = $dep[2];
$coverage_avg = $dep[6];
close DEP;

#Print depth and coverage and on target
print OUT "Average depth of targets: ", "\t", $dep[2],"\n";
print OUT "Coverage of targets: ", "\t", "$coverage_avg%","\n";
printf OUT "On target: \t%0.2f%\n",$on_target/$lengthmaq*100;
close OUT;

###Print uniformity
system("awk 'BEGIN {count=0} {if(\$3 > ($depth/5)){count=count+1}} END {printf \"Uniformity: \\t\%0.2f\%\\n\",(count-1)/(NR-1)*100}' $uni_file >>$outdir/$prefix.summary.txt ");

close FASTQC;
close BED;

