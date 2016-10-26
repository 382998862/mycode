#! /usr/bin/perl -w
#===============================================================================
#         FILE:  download.test.pl
#        USAGE:  Translate GATK_SNP to SNP_format
#  DESCRIPTION:  SNP Translation
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Qing Xie
#      COMPANY:
#      VERSION:
#      CREATED:  07/17/2014 17:31:34 am
#        FIXED:  00/00/2012 00:00:00 am
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Getopt::Long;

my($in,$out,$h);
GetOptions(
        "in=s" => \$in,
        "out:s" => \$out,
        "h=s"  => \$h,
);

my $usage=<<USAGE;
usage   :       perl $0
        -in     input GATK_SNP file
        -out    output the transformed SNP file
        -h      help
USAGE
die $usage unless $in;

open IN,"$in" or die "$!";
open OUT,">$out" or die "$!";

my($ID,$ref,$alt,$info,$sample,$type,$len,$alt_dep,$ref_dep,@alt,@dep,@message,@sample);
print OUT "Chrom\tPosition\tTarget ID\tHotSpot ID\tRef\tCov\tA Reads\tC Reads\tG Reads\tT Reads\tType\tALT\tDeletions\n";
while(<IN>){
	chomp;
	next if $_=~/^#/;
	@message=split(/\t/,$_);
	$ID=$message[2];$ref=$message[3];$alt=$message[4];$info=$message[7];$sample=$message[9];
	$len=length($alt);
	my @base=("A","G","C","T");
	my %dep;
	for(my $i=0;$i<@base;$i++){
		$dep{$base[$i]}=0;
	}
	if($sample=~/\.\/\./){
		$type="N";
	}
	else{
		@sample=split(/:/,$sample);
		if($len>1){
			@alt=split(/,/,$alt);
			@dep=split(/,/,$sample[1]);
			$type="$alt[0]$alt[1]";
			$dep{$alt[0]}=$dep[0];$dep{$alt[1]}=$dep[1];
		}
		if($sample[0]=~/0\/0/){
			$type="$ref$ref";
			$dep{$ref}=$sample[1];
		}
		else{
			if($sample[0]=~/0\/1/){
				$type="$ref$alt";
			}
			else{
				$type="$alt$alt";
			}
			@dep=split(/,/,$sample[1]);
			$dep{$ref}=$dep[0];$dep{$alt}=$dep[1];
		}
	}
	print OUT "chr$message[0]\t$message[1]\t \t$ID\t$ref\t0\t$dep{\"A\"}\t$dep{\"C\"}\t$dep{\"G\"}\t$dep{\"T\"}\t$type\t$alt\t0\n";

}

