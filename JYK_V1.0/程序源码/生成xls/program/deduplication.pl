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
my %hash;
my @lines;
while (<F1>) {
        chomp;
        @lines = split;
        next if exists $hash{$lines[2]};
        $hash{$lines[2]}= 1;
        print F2 "$_\n";
}
