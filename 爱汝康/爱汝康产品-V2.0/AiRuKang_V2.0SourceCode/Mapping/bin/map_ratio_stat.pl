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
GetOptions(\%opts,"id=s","o=s","h");

#&help()if(defined $opts{h});
if(!defined($opts{id}) || !defined($opts{o}) || defined($opts{h}))
{
	print <<"	Usage End.";
	Description:
		
		Version: $ver

	Usage:

		-id          indir of map stat files             must be given

		-o           outfile                             must be given

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
my $outfile = $opts{o} ;

# get stat files
my @statfiles = glob("$indir/*.R*.stat");

# reading stat file 
&stat_mapping_ratio(\@statfiles, $outfile);




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
	my ($shfile, $maxproc) = @_ ;
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

#&stat_mapping_ratio(\@statfiles, $outfile);
sub stat_mapping_ratio()
{
	my ($astatfiles, $outfile) = @_ ;
	my %hstat = ();
	for my $statfile (@{$astatfiles}){
		&reading_stat_file($statfile, \%hstat);
	}
	
	# output
	&output_stat_result($outfile, \%hstat);

	return ;
}

#&reading_stat_file($statfile, \%hstat);
sub reading_stat_file()
{
	my ($statfile, $ahstat) = @_ ;
	my ($sample) = ((basename($statfile))=~/(R\d+L\d+|R\d+)/) ;
	open (IN, $statfile) || die "Can't open $statfile, $!\n" ;
	while (<IN>){
		chomp ;
		if (m/(\d+)\s+\+\s+\d+\s+in\s+total/){
			$ahstat->{$sample}->[0] = $1 ;
		}
		elsif (m/\d+\s+\+\s+\d+\s+mapped\s+\((\d+.\d+)\%/){
			$ahstat->{$sample}->[1] = $1 ;
		}
	}
	close(IN);

	return ;
}

#&output_stat_result($outfile, \%hstat);
sub output_stat_result()
{
	my ($outfile, $ahstat) = @_ ;
	open (OUT, ">$outfile") || die "Can't creat $outfile, $!\n" ;
	print OUT "#Sample\tTotal_reads\tMapped(\%)\n" ;
	for my $sample (sort keys %{$ahstat}){
		print OUT "$sample\t", $ahstat->{$sample}->[0], "\t", $ahstat->{$sample}->[1],"\n" ;
	}
	close(OUT);

	return ;
}


