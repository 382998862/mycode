use strict;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my %opts;
GetOptions(\%opts, "i=s", "od=s", "p=s","h");
if(!defined($opts{i}) || !defined($opts{od}) || !defined($opts{p}) || defined($opts{h}))
{
	print <<"	Usage End.";
	Description:
		This is for simplification of vcf files generated from GATK HaplotypeCaller. 
		The simplified version of vcf files could be used as the appendix of the report of 
		medical projects.

	Usage:
	Forced parameters:
		-i			input HC vcf file					<dir>        must be given
		-od			out dir					            <str>        must be given
		-p			prefix of             <dir>        must be given
	Usage End.
	exit(1);
}
my $vcf = $opts{i};
my $outdir = $opts{od};
my $prefix = $opts{p};
open(IN, "$vcf") or die "no such file";
open(OUT, ">$outdir/$prefix.simple.vcf");
print OUT "Symbol\t", "Chromosome\t","Position\t", "dbSNP\t","Reference\t","Alternative\t","Quality\t","Effect\t","Genotype\n";
while(<IN>){
	if ($_ !~ /^#/) {
		my $eff;
		my $sym;
		my %hash;
		my $gt;
		my $genotype;
		my @line = split(/\t/, $_);
		my @anno = split(/;/, $line[7]);
		foreach my $item (@anno) {
			my ($i ,$j) = split (/=/, $item);
			$hash{$i} = $j;
			}	
		my @key = keys(%hash);
		if(grep /SNPEFF_EFFECT/, @key){
			$eff = $hash{"SNPEFF_EFFECT"};
		}
		if(grep /SNPEFF_GENE_NAME/, @key){
			$sym = $hash{"SNPEFF_GENE_NAME"};
		}else{
			$sym = "";
		}
		
		my @info = split(/:/, $line[9]);
		$gt = $info[0];
		if ($gt eq "1/1") {
			$genotype = "Homozygous";
		}else{
			$genotype = "Heterozygous";
		}	
		my @record = ($sym,@line[0..5],$eff,$genotype,);
		print OUT join("\t", @record),"\n";
	}
}
close (IN);
close (OUT);