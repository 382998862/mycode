#!usr/bin/perl -w
use strict;
use Data::Dumper;

#my $file_clin = "/home/tengwj/Database/clinvar/Database-2016-02-19.tsv";
my $file_clin = "/share/nas1/tengwj/Pipeline/Database/Database1.5.xls";
my $file_input = "$ARGV[0]";
my $file_out = "$ARGV[1]";

open (FIN,$file_clin) || die "clin?\n";
my %hash;
while(<FIN>){
    chomp;
    next if (/^id/);
    my @line = split/\t/,$_;
    my $key = $line[2]."_".$line[3]."_".$line[6]."_".$line[7];
    $hash{$key} = $_;
}
close FIN;
#print Dumper %hash;


open (FIN1,$file_input)||die"input?\n";
open (FOUT,">$file_out");
my %hash2;
while(<FIN1>){
    chomp;
#    next if (/^#/);
    my @line = split/\t/,$_;
    my $detail = $_;
    my $site = $line[2]."_".$line[3]."_".$line[5]."_".$line[6];
#    print "$site\n";
    if (exists $hash{$site}) {
        print FOUT "$detail\t$hash{$site}\n";
    }
    else {
        print FOUT "$detail\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\-t\-t\-t\-t\-t-\n";
    }
}
close FIN1;
close FOUT;
