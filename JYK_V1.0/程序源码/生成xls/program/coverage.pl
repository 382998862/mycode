#!/usr/bin/perl
use strict;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

my %opts;
GetOptions(\%opts,"i=s","o=s");
my $I  = $opts{i} ;
my $O  = $opts{o} ;

my $fileExist = -e "$O";
unless( $fileExist )
{
        open(F3,">>$O") or die "open error:$!";
        print F3 "Chrom\tPosition\tRs\tRef\tVariant\tQuality\tAllele Call\tVariant Depth\tSample Depth\tFrequencys\tcover\n" ;
        close(F3);
}

open(F1,"$I") or die "open error:$!";
open(F,">>$O") or die "open error:$!";

my @lines=<F1> ;
my $i=0;
while($i<@lines){
        chomp;
        my @l = split "\t",$lines[$i];
        $lines[$i] =~ s/\n//g;
        if($l[8] > 30)
        {
        print F $lines[$i]."\t"."all_coverage"."\n";
        } 
        else
        {
        print F $lines[$i]."\t"."low_coverage"."\n";
        }
        $i++;
}

close (F1);
close (F);
