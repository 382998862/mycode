$outdir = "/share/nas1/macc/Yincengceng/Results";
$outprefix = "disease_001";
$variant_file = "$outdir/SNP/variant_calling/$outprefix.formal.vcf";
$Bin= "/share/nas1/macc/Reseq/SNPCalling";
$ref = "/share/nas1/macc/Yincengceng/Results/Ref/ref.genome.fa";

&SimpleAnno($variant_file);

sub SimpleAnno($variant_file)
{
print "perl $Bin/SNPAnnotation_v1.2.pl -i $variant_file -od $outdir/Anno -o $outprefix -r $ref -s Human -mode SNP\n";

mkdir "$outdir/Anno_$optprefix";
system("perl $Bin/SNPAnnotation_v1.2.pl -i $variant_file -od $outdir/Anno_$optprefix -o $outprefix -r $ref -s Human -mode SNP");
open(IN, "$outdir/Anno_$optprefix/$outprefix.formal.anno.gatk.vcf") or die "no such file";

open(OUT, ">$outdir/Anno_$optprefix/$outprefix.anno.gatk.simple.vcf") or die "cannot creat file";
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
		#print $anno[1],"\n";
		foreach my $item (@anno) {
			#print $item,"\n";
			my ($i ,$j) = split (/=/, $item);
			$hash{$i} = $j;
			}
		#print %hash;		
		my @key = keys(%hash);
		#print $key[1],"\t";
		if(grep /SNPEFF_EFFECT/, @key){
			$eff = $hash{"SNPEFF_EFFECT"};
		}
		if(grep /SNPEFF_GENE_NAME/, @key){
			$sym = $hash{"SNPEFF_GENE_NAME"};
		}else{
			$sym = "";
		}
		#print $sym,"\t",$eff,"\n";
		
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
}
