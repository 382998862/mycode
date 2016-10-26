#!/usr/bin/perl
use strict;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);
#检益康结果.xls - SNP.144

my %opts;
GetOptions(\%opts,"i1=s","i2=s","o=s");
my $I1  = $opts{i1} ;
my $I2  = $opts{i2} ;
my $O = $opts{o} ;


open(F1,"$I1") or die "open error:$!";
open(F2,"$I2") or die "open error:$!";
open(F,">>$O") or die "open error:$!";

my @lines1=<F1> ;
my @lines2=<F2> ;

my %hash;
my $i=1;
while($i<@lines1){
        chomp;
        my @l1 = split "\t",$lines1[$i];
        $hash{$l1[3]}=1;
        $i++;
}

my $j=1;
while($j<@lines2){                                           #判断存在
        chomp;
        my @l2 = split "\t",$lines2[$j];
        if(exists $hash{$l2[2]})
        {
        print F $lines2[$j];
        }
        $j++;
        }

close (F1);
close (F2);
close (F);
