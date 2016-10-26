#!/usr/bin/perl -w
# 
# Copyright (c) BIO_MARK 2014
# Writer:         Dengdj <dengdj@biomarker.com.cn>
# Program Date:   2014
# Modifier:       Dengdj <dengdj@biomarker.com.cn>
# Last Modified:  2014.
my $ver="1.0.0";

use strict;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

######################请在写程序之前，一定写明时间、程序用途、参数说明；每次修改程序时，也请做好注释工作

my %opts;
GetOptions(\%opts,"id=s","p=s","m=s","rl=s","n=s","od=s","h" );

#&help()if(defined $opts{h});
if(!defined($opts{id}) || !defined($opts{p}) || !defined($opts{n}) || !defined($opts{rl}) || !defined($opts{od}) || defined($opts{h}))
{
	print <<"	Usage End.";
	Description:
		
		Version: $ver

	Usage:

		-id          indir of bam files                                <dir>           must be given

		-rl          reference length file                             <file>          must be given

		-od          outdir of stat result                             <dir>           must be given

		-p           outfile prefix                                    <str>           must be given

		-n           chr number for draw[0 for all]                    <int>           must be given

		-m           max process for qsub, default 25                  <int>           optional

		-h           Help document

	Usage End.

	exit;
}

###############Time
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";
################
# get parameters
my $indir = $opts{id} ;
$indir = &ABSOLUTE_DIR($indir);
my $reflen_file = $opts{rl};
$reflen_file = &ABSOLUTE_DIR($reflen_file);
my $outdir = $opts{od} ;
mkdir $outdir ;
$outdir = &ABSOLUTE_DIR($outdir);
my $outprefix = $opts{p} ;
my $maxproc = defined $opts{m} ? $opts{m} : 25 ;
my $chr_num = $opts{n} ;
my $sh_dir = "$outdir/sh_dir" ;
mkdir $sh_dir ;
my $picard_dir = "/share/nas2/genome/biosoft/picard-tools/current/" ;
my @bamfiles = ();
&get_bamfiles(\@bamfiles, $indir);

# get depth file use samtools
my $adepth_files = &generate_depth_file(\@bamfiles);

# static map ratio
my ($map_stat_file) = &generate_map_ratio(\@bamfiles);
# static depth and coverage
#my ($adepth_dis_fils, $depth_stat_file) = &stat_depth_and_coverage($adepth_files);
# merge map and depth stat result
#&merge_stat_file($map_stat_file, $depth_stat_file);

# draw reads depth distribution
#&draw_reads_depth_distribution($adepth_dis_fils);

# draw coverage depth distribution
#&draw_coverage_depth_distribution($adepth_files);

# draw insert size
#&draw_insert_size_distribution(\@bamfiles);

###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd Time :[$Time_End]\n\n";

###############Subs
sub sub_format_datetime {#Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub ABSOLUTE_DIR
{ #$pavfile=&ABSOLUTE_DIR($pavfile);
	my $cur_dir=`pwd`;
	$cur_dir =~ s/\n$//;
	my ($in)=@_;
	my $return="";
	
	if(-f $in)
	{
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;
		$dir =~ s/\n$// ;
		$return="$dir/$file";
	}
	elsif(-d $in)
	{
		chdir $in;$return=`pwd`;
		$return =~ s/\n$// ;
	}
	else
	{
		warn "Warning just for file and dir\n";
		exit;
	}
	
	chdir $cur_dir;
	return $return;
}

# &show_log("txt")
sub show_log()
{
	my ($txt) = @_ ;
	my $time = time();
	my $Time = &sub_format_datetime(localtime($time));
	print "$Time:\t$txt\n" ;
	return ($time) ;
}

#&run_or_die($cmd);
sub run_or_die()
{
	my ($cmd) = @_ ;
	&show_log($cmd);
	my $flag = system($cmd) ;
	if ($flag != 0){
		&show_log("Error: command fail: $cmd");
		exit(1);
	}
	&show_log("done.");
	return ;
}

## qsub
sub qsub()
{
	my ($shfile) = @_ ;
	if (`hostname` =~ /cluster/){
		my $cmd = "perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $maxproc --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}
	else{
		my $cmd = "ssh cluster -Y perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $maxproc --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}

	return ;
}

## get bam files
sub get_bamfiles()
{
	my ($abamfiles, $dir) = @_ ;
	@{$abamfiles} = glob("$dir/*.bam");
	if (scalar (@{$abamfiles}) == 0){
		&show_log("No bam file found, please check") ;
		exit (1);
	}

	return ;
}

#my @depthfiles = &generate_depth_file(\@bamfiles);
sub generate_depth_file()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/depth" ;
	mkdir $dir ;
	my @depth_files = ();
	my $shfile = "$sh_dir/samtools.depth.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		(my $basename = basename($bamfile)) =~ s/bam$/depth/ ;
		my $outfile = "$dir/$basename" ;
		print SH "samtools depth $bamfile > $outfile\n" ;
		push @depth_files, $outfile ;
	}
	close(SH);
	&qsub($shfile);

	return(\@depth_files);
}

#&generate_map_ratio(\@bamfiles);
sub generate_map_ratio()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/map_stat" ;
	mkdir $dir ;
	my $shfile = "$sh_dir/samtools.stat.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		(my $basename = basename($bamfile)) =~ s/bam$/stat/ ;
		my $outfile = "$dir/$basename" ;
		print SH "samtools flagstat $bamfile > $outfile\n" ;
	}
	close(SH) ;
	&qsub($shfile) ;

	# merge stat result
	my $outfile = "$dir/$outprefix.map_stat.xls" ;
	my $cmd = "perl $Bin/bin/map_ratio_stat.pl -id $dir -o $outfile" ;
	&run_or_die($cmd);

	return ($outfile) ;
}

#&stat_depth_and_coverage(\@depth_files);
sub stat_depth_and_coverage()
{
	my ($adepth_files) = @_ ;
	my @depth_dis_files = ();
	my $dir = "$outdir/depth_stat" ;
	mkdir $dir ;
	my $shfile = "$sh_dir/depth.stat.sh" ;
	open (SH, ">$shfile") || die "Can't open $shfile, $!\n" ;
	for my $depth_file (@{$adepth_files}){
		my $basename = basename($depth_file) ;
		my $outfile = "$dir/$basename" ;
		print SH "perl $Bin/bin/depth_coverage_stat.pl -i $depth_file -l $reflen_file -o $outfile\n" ;
		push @depth_dis_files, "$outfile.dis" ;
	}
	close(SH);
	&qsub($shfile);

	# merge
	my $outfile = "$dir/$outprefix.depth_stat.xls" ;
	my $cmd = "perl $Bin/bin/depth_coverage_result_merge.pl -id $dir -o $outfile" ;
	&run_or_die($cmd);

	return (\@depth_dis_files, $outfile);
}

#&merge_stat_file($map_stat_file, $depth_stat_file);
sub merge_stat_file()
{
	my ($map_stat_file, $depth_stat_file) = @_ ;
	my $dir = "$outdir/result" ;
	mkdir $dir ;
	my $outfile = "$dir/$outprefix.merge_stat.xls" ;
	my $cmd = "perl $Bin/bin/merge_stat.pl -a $map_stat_file -b $depth_stat_file -o $outfile" ;
	&run_or_die($cmd);

	return ;
}

#&draw_reads_depth_distribution($adepth_dis_fils);
sub draw_reads_depth_distribution()
{
	my ($adepth_dis_fils) = @_ ;
	my $dir = "$outdir/depth_distr_png" ;
	mkdir $dir ;
	my $shfile = "$sh_dir/depth_distr.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $depth_dis_file (@{$adepth_dis_fils}){
		my $basename = basename($depth_dis_file) ;
		my $outfile = "$dir/$basename.png" ;
		print SH "$Bin/bin/dualAxis.r -i $depth_dis_file -o $outfile --x.col 1 --y1.col 2 --y2.col 3 --x.lab \"Sequencing depth\" --y1.lab \"Percent of base\" --y2.lab \"Percent of cumulative base\" --legend.xpos 0.7 --legend.ypos 0.9\n" ;
	}
	close(SH);
	&qsub($shfile);

	return ;
}

#&draw_coverage_depth_distribution(\@depthfiles);
sub draw_coverage_depth_distribution()
{
	my ($adepth_files) = @_ ;
	my $dir = "$outdir/coverage_distr_png" ;
	mkdir $dir ;
	my $shfile = "$sh_dir/coverage_distr.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $depth_file (@{$adepth_files}){
		my $basename = basename($depth_file) ;
		print SH "perl $Bin/bin/plotReadDensity.pl -i $depth_file -k $basename -o $dir -n $chr_num\n" ;
	}
	close(SH);
	&qsub($shfile);

	return ;
}

#&draw_insert_size_distribution(\@bamfiles);
sub draw_insert_size_distribution()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/insert_distr_pdf" ;
	mkdir $dir ;
	my $shfile = "$sh_dir/insert_distr.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		(my $basename = basename($bamfile)) =~ s/.bam$// ;
		my $histogram_file = "$dir/$basename.insert.pdf" ;
		my $outfile = "$dir/$basename.insert" ;
		my $cmd = "java -jar $picard_dir/CollectInsertSizeMetrics.jar VALIDATION_STRINGENCY=LENIENT HISTOGRAM_FILE=$histogram_file" ;
		$cmd .= " INPUT=$bamfile OUTPUT=$outfile STOP_AFTER=10000000 DEVIATIONS=20" ;
		print SH $cmd,"\n" ;
	}
	close(SH);
	&qsub($shfile);
	
	return ;
}


