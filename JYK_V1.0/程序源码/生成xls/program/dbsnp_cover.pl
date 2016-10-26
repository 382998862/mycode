#!/usr/bin/perl
use strict;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);
#（SNP.144 - 检益康结果.xls）在检益康范围的覆盖情况。 

my %opts;
GetOptions(\%opts,"i1=s","i2=s","o=s");
my $I1  = $opts{i1} ;
my $I2  = $opts{i2} ;
my $O  = $opts{o} ;

open(F1,"$I1") or die "open error:$!";
open(F2,"$I2") or die "open error:$!";
open(F,">>$O") or die "open error:$!";

my @lines1=<F1> ;
my @lines2=<F2> ;

my $i = 0;
while($i < @lines1){
                chomp $lines1[$i];
                my @l1 = split "\t",$lines1[$i];
                my $j = 0;
                while($j < @lines2){
                chomp $lines2[$j];
                my @l2 = split "\t",$lines2[$j];

                if($l1[0] eq $l2[0] && $l1[1] >= $l2[1] && $l1[1] <= $l2[2])
                {
                        print F $lines1[$i]."\t".$l2[4]."\t".$l2[4]."\t"."1"."\n";
                }
                $j++;
                }
        $i++;
}
close(F1);
close(F2);
close(F);