#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

my %opts;
GetOptions(\%opts,"i1=s","i2=s","o=s");
my $I1  = $opts{i1} ;   #检益康结果
my $I2  = $opts{i2} ;   #检益康的bed区间
my $O = $opts{o} ;      #生成的结果

system("perl /share/nas1/sunqh/product/JYK/JYK/program/rs_exit.pl -i1 $I1 -i2 /share/nas1/sunqh/product/JYK/JYK/program/JYK_snp.txt -o $O.1.txt");
system("perl /share/nas1/sunqh/product/JYK/JYK/program/exit.pl -i1 /share/nas1/sunqh/product/JYK/JYK/program/JYK_snp.txt -i2 $I1 -o $O.2.txt");
system("perl /share/nas1/sunqh/product/JYK/JYK/program/dbsnp_cover.pl -i1 $O.1.txt -i2 $I2 -o $O.3.txt");
system("perl /share/nas1/sunqh/product/JYK/JYK/program/snp_exit.pl -i1 $O.3.txt -i2 $O.1.txt -o $O.4.txt");
system("cat $O.2.txt $O.3.txt $O.4.txt > $O.5.txt");
system("perl /share/nas1/sunqh/product/JYK/JYK/program/deduplication.pl -i $O.5.txt -o $O.6.txt");
system("perl /share/nas1/sunqh/product/JYK/JYK/program/coverage.pl -i $O.6.txt -o $O.txt");
system("mv $O.1.txt $O.2.txt $O.3.txt $O.4.txt $O.5.txt $O.6.txt tmp/")
