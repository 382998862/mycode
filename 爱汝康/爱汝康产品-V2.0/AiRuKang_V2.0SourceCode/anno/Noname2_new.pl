#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;


my $file_anno1 = $ARGV[0];
my $file_anno2 = $ARGV[1];
my $file_out = $ARGV[2];


open(FIN,$file_anno2)||die"$!";
my %hash_1;
while(<FIN>){
    chomp;
    my @line = split/\t/,$_;
    my $site = $line[3]."_".$line[4]."_".$line[6]."_".$line[7];
#    print "3467\t$site\n";
    $hash_1{$site} = $_;
}
close FIN;


open(FIN1,$file_anno1)||die"$!";
open(FOUT,">$file_out");
while(<FIN1>){
    chomp;
    my @line = split/\t/,$_;
    my $site_use = $line[2]."_".$line[3]."_".$line[5]."_".$line[6];
#    print "2356\t$site_use\n";
    if (exists $hash_1{$site_use}){
        print FOUT "$_\t$hash_1{$site_use}\n";
#        print "$_\t$hash_1{$site_use}\n";
    }
    else {
        print FOUT "$_\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n";
#        print "$_\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n";
    }
}
close FIN1;
close FOUT;

=a

my $num = 1;
while(<FOUT>){
    chomp;
    my @line = split/\t/,$_;
    my $num = $num++;
    if ($line[10] ne "-") {
        my ($num_line) = $line[10] =~ /line(\w+)/;
        if ($num_line == $num) {
	  next;
        }
        else {
	  print "ERROR\tline_$num\n";
        }
    }
}
close FOUT;
=a

open(FIN2,$file_input)||die"inputfile?\n";
open(FOUT,">>$file_out");
my $num_3 = 1;
while(<FIN2>){
	chomp;
	next if (/^Chrom/);
	my $num_3 = $num_3++;
	my $detail = $_;
	if (exists $hash1{$num_3} && (exists $hash2{$num_3})) {
		print FOUT "$detail\t$hash1{$num_3}\t$hash2{$num_3}\n";
	}
	elsif ((exists $hash1{$num_3} && (!exists $hash2{$num_3}))) {
		print FOUT "$detail\t$hash1{$num_3}\t-\t-\n";
	}
	else {
		print "what?!\n";
	}
}
close FIN2;
close FOUT;
=cut
