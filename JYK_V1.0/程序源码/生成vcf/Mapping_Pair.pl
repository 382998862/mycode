#!/usr/bin/perl -w
# 
# Copyright (c) BIO_MARK 2014
# Writer:         Dengdj <dengdj@biomarker.com.cn>
# Program Date:   2014
# Modifier:       Dengdj <dengdj@biomarker.com.cn>
# Last Modified:  2014.
my $ver="1.4";

use strict;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

######################请在写程序之前，一定写明时间、程序用途、参数说明；每次修改程序时，也请做好注释工作

my %opts;
GetOptions(\%opts,"c=s","od=s","p=s","m=s","h" );

#&help()if(defined $opts{h});
if(!defined($opts{c}) || !defined($opts{p}) || !defined($opts{od}) || defined($opts{h}))
{
	print <<"	Usage End.";
	Description:
		
		Version: $ver
		v1.3:	Support multi-library for one sample.
		     	Allowe appoint insert size(for bwa, insert-size has estimated itself,
		     	max-insert-size is only used when there are not enough good alignment
		     	to infer the distribution of insert sizes).
		v1.4:	Allow assign mismatch number for bwa aln.

	Usage:

		-c           config file <infile>                     must be given

		-od          outdir      <outdir>                     must be given

		-p           outfile prefix                           must be given

		-m           max process for qsub, default 25         optional

		-h           Help document

	Usage End.

	exit;
}

###############Time
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";
################

## init parameter
my $configfile = $opts{c} ;
my $outdir = $opts{od} ;
mkdir $outdir ;
$outdir = &ABSOLUTE_DIR($outdir) ;
my $outprefix = $opts{p} ;
my $maxproc = defined $opts{m} ? $opts{m} : 25 ;
my %hconfig = () ;
my %hsamples = () ;
my $picard_dir = "/share/nas2/genome/biosoft/picard-tools/current/" ;
mkdir "$outdir/bwa_mid" ;
mkdir "$outdir/result" ;
my $tmp_dir = "$outdir/tmp" ;
mkdir $tmp_dir ;
my $sh_dir = "$outdir/sh_dir" ;
mkdir $sh_dir ;

## reading config file
&reading_config_file($configfile, \%hconfig) ;

## check config file's correctness
&check_config_file(\%hconfig, \%hsamples) ;

## mapping with bwa mem
&mapping_mem(\%hconfig, \%hsamples);

##Summary mapping results
&Summary_mapping(\%hconfig, \%hsamples);

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

## show_log()
sub show_log()
{
	my ($txt) = @_ ;
	my $time = time();
	my $Time = &sub_format_datetime(localtime($time));
	print "$Time:\t$txt\n" ;
	return ($time) ;
}

## reading config file
sub reading_config_file()
{
	my ($configfile, $ahconfig) = @_ ;
	open (CFG, $configfile) || die "Can't open $configfile, $!\n" ;
	while (<CFG>){
		chomp ;
		next if (m/^\#/ || m/^\s*$/) ;
		my ($key, $value) = split ;
		$ahconfig->{$key} = $value ;
	}
	close(CFG);

	return ;
}

## check config file's correctness
sub check_config_file()
{
	my ($ahconfig, $ahsamples) = @_ ;
	# ref
	if (!defined $ahconfig->{Ref}){
		&show_log("ERROR:\tundefined Ref(reference file) in config file") ;
		exit (1) ;
	}
	if (!(-f $ahconfig->{Ref})){
		&show_log("ERROR:\treference file not exist:".($ahconfig->{Ref})) ;
		exit (1) ;
	}
	if (!defined $ahconfig->{RefLen}){
		&show_log("ERROR:\tundefined RefLen(reference length) in config file") ;
		exit (1);
	}
	# insert size
	if (!defined $ahconfig->{Ins}){
		&show_log("ERROR:\tundefined Ins(insert size) in config file") ;
		exit (1) ;
	}
	# get reads
#	my %hsamples = ();
	for my $key (keys %{$ahconfig}){
		if ($key =~ /^(R\d+)-(\d)$/ || $key =~ /^(R\d+L\d+)-(\d)$/){
#			$hsamples{$1}->[$2 - 1] = $ahconfig->{$key} ;
			$ahsamples->{$1}->[$2 - 1] = &ABSOLUTE_DIR($ahconfig->{$key}) ;
		}
	}
	# check reads
	if (scalar (keys %{$ahsamples}) == 0){
		&show_log("ERROR:\tundefined reads info in config file") ;
		exit (1);
	}
	for my $sample (keys %{$ahsamples}){
		if (!(-f $ahsamples->{$sample}->[0])){
			&show_log("ERROR:\tsample($sample) can't find file ".($ahsamples->{$sample}->[0])) ;
			exit (1);
		}
		if (!(-f $ahsamples->{$sample}->[1])){
			&show_log("ERROR:\tsample($sample) can't find file ".($ahsamples->{$sample}->[1])) ;
			exit (1);
		}
	}

	return ;
}

## mapping with bwa mem
sub mapping_mem()
{
	# get parameters
	my ($ahconfig, $ahsamples) = @_ ;
	my $ref = $ahconfig->{Ref} ;
	my $map_mem_sh = "$sh_dir/$outprefix.map.mem.sh" ;
	open (SH, ">$map_mem_sh") || die "can't open $map_mem_sh, $!\n" ;
	for my $sample (sort keys %{$ahsamples}){
		my $sample_id = $sample ;
		$sample_id = $1 if ($sample =~ /(R\d+)L\d+/) ;
		print SH "bwa mem -M -t 10 -R \"\@RG\tID:$sample\tLB:$sample\tPL:ILLUMINA\tSM:$sample_id\" " ;
		print SH " $ref", " $ahsamples->{$sample}->[0]", " $ahsamples->{$sample}->[1]" ;
		print SH " | gzip > $outdir/bwa_mid/$outprefix.$sample.sam.gz\n" ;
	}
	close(SH);
	&qsub($map_mem_sh);

	# sort and transform to bam
	my $map_bam_sh = "$sh_dir/$outprefix.map.bam.sh" ;
	open (SH, ">$map_bam_sh") || die "Can't creat $map_bam_sh, $!\n" ;
	for my $sample (sort keys %{$ahsamples}){
		print SH "java -Djava.io.tmpdir=$tmp_dir -Xmx20G -jar $picard_dir/SortSam.jar VALIDATION_STRINGENCY=LENIENT INPUT=$outdir/bwa_mid/$outprefix.$sample.sam.gz" ;
		print SH " OUTPUT=$outdir/result/$outprefix.$sample.sort.bam SORT_ORDER=coordinate TMP_DIR=$tmp_dir\n" ;
	}
	close(SH);
	&qsub($map_bam_sh);
	# index bam file
	my $bam_idx_sh = "$sh_dir/$outprefix.bam.idx.sh" ;
	open (SH, ">$bam_idx_sh") || die "Can't creat $bam_idx_sh, $!\n" ;
	for my $sample (sort keys %{$ahsamples}){
		print SH "samtools index $outdir/result/$outprefix.$sample.sort.bam\n" ;
	}
	close(SH);	
	&qsub($bam_idx_sh);
	return ;
}

##Summary mapping results
sub Summary_mapping()
{
	my ($ahconfig, $ahsamples) = @_;
	my $BED = $ahconfig->{BED};
	my $Depth = $ahconfig->{Depth};
	my $ref = $ahconfig->{Ref};
	my $od = "$outdir/Summary";
	mkdir $od;
	my $summary_sh = "$sh_dir/$outprefix.summary.sh";
	open(SH, ">$summary_sh") || die "can not creat summary sh!\n";
	for my $sample (sort keys %{$ahsamples}){
		my $BAM = "$outdir/result/$outprefix.$sample.sort.bam";
		print SH "perl $Bin/../Program/SummaryStat_Pair.pl -i $BAM -r $ref -od $od -bed $BED -p $outprefix.$sample -d $Depth \n";
	}
	close(SH);
	&show_log("Summrizing the FASTQ and mapping results.");
	&qsub($summary_sh);
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
#sub qsub()
#{
#	my ($shfile) = @_ ;
#	if (`hostname` =~ /cluster/){
#		my $cmd = "perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $maxproc --reqsub $shfile --independent" ;
#		&run_or_die($cmd);
#	}
#	else{
#		my $cmd = "ssh cluster -Y perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $maxproc --reqsub $shfile --independent" ;
#		&run_or_die($cmd);
#	}

#	return ;
#}

sub qsub()
{
        my ($shfile) = @_ ;
        my $cmd = "sh $shfile" ;
	&run_or_die($cmd);
        return;
}
