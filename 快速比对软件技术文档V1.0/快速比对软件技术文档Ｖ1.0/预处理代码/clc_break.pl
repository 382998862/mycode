#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

my %opts;
GetOptions(\%opts,"i=s","o=s");
my $I  = $opts{i} ;
my $O  = $opts{o} ;

my @dir;
my $filename;
my $dirname = "$I/";         #指定一个目录
opendir ( DIR, $dirname ) || die "Error in opening dir $dirname\n";
while( ($filename = readdir(DIR))){
if($filename =~ /.txt/) {
   #print "$filename\n";
   foreach($filename)         #遍历文件
   {
   system("perl break.pl -i $I/$filename -o $O/$filename.txt") ;
   }
}
}
