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

open(DATA,"$I") or die "open error:$!";

my @file_name = ("0".."30");
my $data = do{local $/="",<DATA>};
    map{my @arr = split/>\s*/;
        for (@arr){
            my $file = shift@file_name;
            open FH,">chr$file.txt" or die "$!";
            print FH $_;
            close FH;
        }

        }$data;