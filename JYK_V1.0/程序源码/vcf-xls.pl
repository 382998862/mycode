#!/usr/bin/perl
use strict;
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

my %opts;
GetOptions(\%opts,"i=s" ,"o=s");
my $I  = $opts{i} ;
my $O = $opts{o} ;

open(F1,"$I") or die "open error:$!";

my $fileExist = -e "$O";
unless( $fileExist )
{
        open(FILE3,">>$O") or die "open error:$!";
        print FILE3 "Chrom\tPosition\tRs\tRef\tVariant\tQuality\tAllele Call\tVariant Depth\tSample Depth\tFrequencys\n" ;
        close(FILE3);
}

open(F,">>$O") or die "open error:$!";

my @lines1=<F1> ;

my $i = 0;

while($i < @lines1){
                if ($lines1[$i] !~ /^#/) {
                chomp $lines1[$i];
                my @l = split "\t",$lines1[$i];    #第一行分割

                #my @l8 = split ";",@l[7];     #第八列分割
                #my @l9 = split ":",@l[8];     #第九列分割

                my @ll = split ":",$l[9];    #第十列分割

                my @lll = split ",",$ll[1] ;

                if ($ll[0] eq "0/1")
                {
                print F $l[0]."\t".$l[1]."\t".$l[2]."\t".$l[3]."\t".$l[4]."\t".$l[5]."\t"."Het"."\t".$lll[1]."\t".$ll[2]."\t".($lll[1]/$ll[2])."\n";
                }
                elsif ($ll[0] eq "1/2")
                {
                my @l4 = split ",",$l[4] ;  #第四列分割
                print F $l[0]."\t".$l[1]."\t".$l[2]."\t".$l[3]."\t".$l4[0]."\t".$l[5]."\t"."Het"."\t".$lll[1]."\t".$ll[2]."\t".($lll[1]/$ll[2])."\n";
                print F $l[0]."\t".$l[1]."\t".$l[2]."\t".$l[3]."\t".$l4[1]."\t".$l[5]."\t"."Het"."\t".$lll[2]."\t".$ll[2]."\t".($lll[2]/$ll[2])."\n";
                }

                else
                {
                print F $l[0]."\t".$l[1]."\t".$l[2]."\t".$l[3]."\t".$l[4]."\t".$l[5]."\t"."Hom"."\t".$lll[1]."\t".$ll[2]."\t".($lll[1]/$ll[2])."\n";
                }

                }
                $i++;

}
close(F1);
close(F2);
close(F);
