#usr/bin/perl -w
use strict;
use Data::Dumper;
use Getopt::Long;


my ($file_anno,$file_mutpos,$file_vcf);
GetOptions (
            "help|?"=>\&USAGE,
            "result_file:s"=>\$file_anno,
            "mutpos_file:s"=>\$file_mutpos,
            "vcf_file:s"=>\$file_vcf,
)or \&USAGE;
&USAGE unless ($file_anno and $file_mutpos and $file_vcf);


my $file_db = "/share/nas1/tengwj/Pipeline/Database/Database1.5.xls";  #v1.5
###my $file_anno = "/share/nas1/tengwj/Workspace/54.hotspot_file/04.pileline_new/test.R06.result.xls"; #getopt
#my $file_anno = "/share/nas1/tengwj/Workspace/55.Technology_Files/testpro/test.R05.result.xls";
#my $file_mutpos = "/share/nas1/tengwj/Workspace/54.hotspot_file/04.pileline_new/2.mutpos"; #getopt
###my $file_mutpos = "/share/nas1/tengwj/Workspace/55.Technology_Files/testpro/2.mutpos";
###my $file_vcf = "/share/nas1/tengwj/Workspace/55.Technology_Files/testpro/test.vcf";
#my $file_out = "test.out";


open(FIN,$file_anno)||die"file_anno?\n";   #input file
my %hash_anno;
while(<FIN>){
    chomp;
    next if (/^Chrom/);
    my @line = split/\t/,$_;
    my $key = $line[0]."_".$line[1]."_".$line[2]."_".$line[3];
    $hash_anno{$key} = $_;
}
close FIN;
#print Dumper %hash_anno;

open (FIN1,$file_db)||die"file_db?\n";
my %hash_db;
while(<FIN1>){
    chomp;
#    next if (/^#/);
    my @line = split/\t/,$_;
    my $detail = "$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]\t$line[11]\t$line[12]\t$line[13]\t$line[14]\t$line[15]\t$line[18]\t$line[19]";
    my $site_cmpr = $line[2]."_".$line[3]."_".$line[6]."_".$line[7];  # Has repeat Total:8424. Site_cmpr (compare) for generating hash.
    #my $site_db = $line[2]."_".$line[3]."_".$line[6];  # Site_db for mutpos.
#    print "$site\n";
    if (!exists $hash_anno{$site_cmpr}) {   # 忘记为什么这么写了。。。
#        print "??$detail\t$hash_anno{$site}\n";
        $hash_db{$site_cmpr} = "$detail";
    }
}
#print Dumper %hash_db;
close FIN1;


open(FIN2,$file_mutpos)||die"$!";   #python　script results .
my %hash_mutpos;
while(<FIN2>){
    chomp;
    s/\r//;
    my @line = split/\t/,$_;
    my $site = $line[0]."_".$line[2]."_".$line[1];
 #   print "222\t$site\n";
    $hash_mutpos{$site} = $_;
}
close FIN2;
#print Dumper %hash_mutpos;

open(FIN3,$file_vcf)||die"VCFfile?\n";  #the frequence in this file
my %hash_vcf;
while(<FIN3>){
    chomp;
    next if (/^#/);
    my @line = split/\t/,$_;
    my ($freq) = $line[9] =~ /:\d+:\d+:\d+:\d+:\d+:(\S+\%)/;   #  /:(\d+\.\d+){0,1}/
    my ($syn) = $line[9] =~ /^(\d\/\d):/;
#    print "$freq\t$syn\n";
    my $detail = $syn."\t".$freq;
    my ($ref,$alt,$site);
    my $chr = $line[0];
    if (length($line[3]) > 1){   #del
        $site = $line[1]+1;
        $ref = substr ($line[3],1);
        $alt = "-";
    }
    elsif (length($line[4]) > 1){ #ins
        $site = $line[1];
        $ref = "-";
        $alt = substr ($line[4],1);
    }
    elsif ( length($line[3]) == 1 && length($line[4]) == 1) {
        $site = $line[1];
        $ref = $line[3];
        $alt = $line[4];
    }
    my $all = $chr."_".$site."_".$ref."_".$alt;
    $hash_vcf{$all} = $detail;
}
close FIN3;
#print Dumper %hash_vcf;

foreach my $key2 (keys %hash_anno) {     #input file
    $key2 =~ /(chr\d+_\d+)_(\w+)_\w+/;
    my $key2_site = $1;
    my $key2_ref = $2;
    my $key2_ref_use = substr($key2_ref,0,1);
    my $key2_mod = $key2_site."_".$key2_ref_use;  # change chr1_11_A_B to  chr1_11_A
#    print "$key2_mod\n";
    if (exists $hash_mutpos{$key2_mod}) {
        print "$hash_anno{$key2}\t$hash_mutpos{$key2_mod}\t$hash_vcf{$key2}\n";
    }
    else {
        print "$hash_anno{$key2}\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t$hash_vcf{$key2}\n";
    }
}


foreach my $key1 (keys %hash_db) {
    $key1 =~ /(chr\d+_\d+)_(\w+)_\w+/;
    my $key1_site = $1;
    my $key1_ref = $2;
    my $key1_ref_use = substr($key1_ref,0,1);
    my $key1_mod = $key1_site."_".$key1_ref_use;
#    print "2222\t$key1_mod\n";
    if (exists $hash_mutpos{$key1_mod}) {
        print "-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t$hash_db{$key1}\t$hash_mutpos{$key1_mod}\t-\t0.0%\n";
    }
    else {
        print "-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t$hash_db{$key1}\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t0.0%\n";
    }
}



sub USAGE
{
    my $usage=<<"Usage";
    Options:\n
        -result_file
        -mutpos_file
        -vcf_file
        
Usage
        print $usage;
        exit;
}
