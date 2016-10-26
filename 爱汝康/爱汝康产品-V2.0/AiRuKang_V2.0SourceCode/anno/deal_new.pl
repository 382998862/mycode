#!usr/bin/perl -w
use strict;

my $file_in = $ARGV[0];
my $file_out = $ARGV[1];

open(FIN,$file_in)||die"input?\n";
open(FOUT,">$file_out");
print FOUT"Chrom\tPosition\tRef\tVariant\tregion.\tgene.\tChromosome\tStart\tEnd\tReference Allelel\tAlternative Allele\tallele.\tQuality\tOriginalCoverage\tsynonymous\texonic_variant_function\tid\tGene\tChrom\tPositionStart\tPositionEnd\tRegion\tRef\tVariant\tcDNAChange\tProtienChange\tMutationType\tClinicSignificance\tDatabase\tLinks\tCosmic\tRsNumber\tPMID\tVariationID\n";
while(<FIN>){
    chomp;
    my @line = split/\t/,$_;
    print FOUT "$line[2]\t$line[3]\t$line[5]\t$line[6]\t$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[11]\t$line[12]\t$line[21]\t$line[22]\t$line[23]\t$line[24]\t$line[25]\t$line[26]\t$line[27]\t$line[28]\t$line[29]\t$line[30]\t$line[31]\t$line[32]\t$line[33]\t$line[34]\t$line[35]\t$line[36]\t$line[39]\t$line[40]\n";
}
close FIN;
close FOUT;
