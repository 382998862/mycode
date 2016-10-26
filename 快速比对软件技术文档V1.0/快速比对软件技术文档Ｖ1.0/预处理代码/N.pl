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


open(F1,"$I") or die "open error:$!";

open(F2,">>$O") or die "open error:$!";


my @lines=<F1> ;


my $i = 0;

while($i < @lines){
                chomp $lines[$i];
                my @l = split "\t",$lines[$i];
                if($l[0]=~/N/){}
                else
                {
                print F2 $lines[$i]."\n";
                }
                $i++;
}
close(F1);
close(F2);

print "T\n" ;
