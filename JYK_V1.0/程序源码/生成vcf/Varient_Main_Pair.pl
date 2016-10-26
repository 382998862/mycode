#!/usr/bin/perl -w
# 
# Copyright (c) BIO_MARK 2014
# Writer:		Xieq <xieq@biomarker.com.cn>
# Program Date:	2014
# Modifier:		Xieq <xieq@biomarker.com.cn>
# Last Modified:2014
my $ver="1.0";

use strict;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

######################Please notify the time, usage, and the explaination; Keep the annotations conspicuously;
#my $Bin="/share/nas1/macc/Reseq";

my %opts;
GetOptions(\%opts,"c=s","p=s","od=s","database=s","threads=s","maxcpu=s","maxproc=s","start=s","end=s","assign=s","h" );
if( !defined($opts{c}) || !defined($opts{p}) || !defined($opts{od}) ||defined($opts{h}))
{
	print <<"	Usage End.";
	Description:
		Version: $ver
		v1.0:	Support multi-library fq for one sample.
				Generating tex report automatically.
				Optimizing dataprocessing for large sample size.
	Usage:
	Forced parameter:
		-c			config file
		-p			outfile prefix
		-od			outdir
	Optional parameter:
		-database	database species list file					optional [/path/to/listfile]
		-maxcpu		max cpu used in these pipline				optional [100]
		-maxproc	max process for qsub						optional [25]
		-threads	threads number used in varaints calling		optional [4]
	Process contral:
		-start		start step									optional [1]
		-end		end step									optional [4]
		-assign		assign some steps to run					optional [n1,n2,n3]
	step number:
					mapping										1
					calling SNP									2
					transforming SNP							3
					generating report							4
	Other parameter:
		-h			Help document

	Usage End.

	exit;
}

###############Time
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";
################

## init parameters
my $config_file = $opts{c} ;
my $outprefix = $opts{p} ;
my $outdir = $opts{od} ;
mkdir $outdir ;
$outdir = &ABSOLUTE_DIR($outdir);
my $maxproc = defined $opts{maxproc} ? $opts{maxproc} : 25 ;
my $thread_num = defined $opts{threads} ? $opts{threads} : 4 ;
my $maxcpu = defined $opts{maxcpu} ? $opts{maxcpu} : 25 ;
my $database = defined $opts{database} ? $opts{database} : "/path/to/listfile" ;
my $region = defined $opts{region} ? $opts{region} : "/home/xudd/workdir/pipline/Reseq/Ref/Hg19.bed";
my $depth = defined $opts{d} ? $opts{d} : 0;
my %hconfig = ();		# parameter in config file
my %hdatabase = ();		# database path
my %hsamples = ();      #samples

## pre-process: get parameter of config and reference
&pre_process();
my @steps = &get_process($opts{assign}, $opts{start}, $opts{end});
&show_log("Analysis list: @steps") ;
for my $step (@steps){
	&run_process($step) ;
}

## get process
sub get_process()
{
	my ($assign, $start, $end) = @_ ;
	my @process = ();
	if (defined $assign){
		@process = split /,/, $opts{assign} ;
		if (defined $start && defined $end){
			for (my $step=$start; $step<=$end; $step+=1){
				push @process, $step ;
			}
		}
		@process = sort {$a<=>$b} @process ;
	}
	else{
		$start ||= 1 ;
		$end ||= 2 ;
		@process = ($start..$end);
	}
	return(@process);
}

####-------- Subs
## pre-process
sub pre_process()
{
	my $begin_time = &show_log("pre-process");
	my @array;
	&get_parameters_from_config_and_check($config_file, \%hconfig, \%hdatabase, \%hsamples) ;
	my @key =  keys %hsamples;
	my $key = $key[0];
	$begin_time = &show_log("Start FastQC..");
	&FastqQC(\%hsamples);
	&show_log(&run_time($begin_time));
}

sub FastqQC()
{
	my ($QCsample) = @_ ;
	my $pwd = $ENV{'PWD'};
	my $fastqc_outdir = "$outdir/FastQC";
	mkdir $fastqc_outdir;
	my $shfile = "$fastqc_outdir/$outprefix.fastqc.sh";
	open (SH, ">$shfile");
	for my $key (sort keys %{$QCsample}) {
		print $key,"\n";
		print SH "/home/sunqh/workdir/product/JYK/process/Program/fastq_qc_stat -q 45 -a $QCsample->{$key}->[0] -b $QCsample->{$key}->[1] -f $outprefix.$key\n";
		print SH "mv $outprefix.$key.acgtn $outdir/FastQC\n";
		print SH "mv $outprefix.$key.qstat $outdir/FastQC\n";
		print SH "mv $outprefix.$key.quality $outdir/FastQC\n";
		print SH "mv $outprefix.$key.stat $outdir/FastQC\n";
	}
	close(SH);
	&qsub($shfile);
}
## run each process
sub run_process()
{
	my ($num) = @_ ;
	SWITCH: {
		$num == 1 && do { &Mapping(); last SWITCH; };
		$num == 2 && do { &CallingSNP(); last SWITCH; };
		$num == 3 && do { &TransformSNP(); last SWITCH; };
		$num == 4 && do { &GeneratingReport(); last SWITCH; };
		print "step number: $num not between 1 to 4\n" ;
		exit (1);
	}

	return ;
}
## quality control of fastq

## mapping to genome
sub Mapping()
{
	my $begin_time = &show_log("Start mapping reads to genome...");
	# generate config file
	my $map_outdir = "$outdir/Mapping" ;
	my $bed = $hconfig{BED};
	my $depth = $hconfig{Depth};
	mkdir $map_outdir ;
	my $map_config = &generate_map_config_file(\%hconfig, $map_outdir);
	my $cmd = "perl $Bin/Program/Mapping_Pair.pl -c $map_config -od $map_outdir -p $outprefix -m $maxproc" ;
	&run_or_die($cmd);
	&show_log(&run_time($begin_time));
}

sub generate_map_config_file()
{
	my ($ahconfig, $map_outdir) = @_ ;
	my $map_config = "$map_outdir/map_config.txt" ;
	open (CFG, ">$map_config") || die "Can't creat file $map_config, $!\n" ;
#	modified by Xudd
#	print CFG "Ref\t$outdir/Ref/ref.genome.fa\n" ;
	print CFG "Ref\t$Bin/Ref/ref.genome.fa\n" ;
	print CFG "RefLen\t", $ahconfig->{RefLen}, "\n" ;
	print CFG "ChrNum\t", $ahconfig->{ChrNum}, "\n";
	print CFG "\n" ;
	print CFG "Ins\t", $ahconfig->{Ins}, "\n" ;
	print CFG "\n" ;
	if (defined $ahconfig->{Quality}){
		print CFG "Quality\t", $ahconfig->{Quality},"\n\n" ;
	}
	my %hsamples = ();
	for my $key (keys %{$ahconfig}){
		if ($key =~ /^(R\d+)-(\d)$/ || $key =~ /^(R\d+L\d+)-(\d)$/){
			$hsamples{$1}->[$2 - 1] = $ahconfig->{$key} ;		
		}
	}
	for my $sample (sort keys %hsamples){
		print CFG "$sample\-1\t", $hsamples{$sample}->[0], "\n" ;
		print CFG "$sample\-2\t", $hsamples{$sample}->[1], "\n" ;
	}
	print CFG "\n" ;
	print CFG "BED\t", $ahconfig->{BED},"\n"; 
	print CFG "Depth\t", $ahconfig->{Depth},"\n";
	close(CFG);

	return ($map_config) ;
}

## calling variants
sub CallingSNP()
{
	my $begin_time = &show_log("Start calling variants...");
	my $var_dir = "$outdir/SNP" ;
	my $indir = "$outdir/Mapping/result" ;
	my $ref = "$Bin/Ref/ref.genome.fa" ;
	my $ploidy = defined $hconfig{Ploidy} ? $hconfig{Ploidy} : 2 ;
	my $db_vcf_file = $hconfig{Dbsnp} ;
	my $bed = $hconfig{BED};
	my $cmd = "perl $Bin/Program/SNPCalling.pl -id $indir -od $var_dir -region $bed -p $outprefix -r $ref -ploidy $ploidy -t $thread_num -m $maxproc -cpu $maxcpu -db $db_vcf_file" ;
	&run_or_die($cmd);
	&show_log(&run_time($begin_time));
}

## Transforming SNP
sub TransformSNP()
{
	my $begin_time = &show_log("Start transforming SNP...") ;
	my $var_dir = "$outdir/TransformSNP.xlsx";
	my $indir = glob("$outdir/SNP/*.snp.*.vcf");
	my $cmd = "perl $Bin/Program/GATK_SNP_input.pl -in $indir -out $var_dir" ;
	&run_or_die($cmd);
	&show_log(&run_time($begin_time));
}

## Generating Report
sub GeneratingReport ()
{
	my $begin_time = &show_log("Start Report generation...");
	my $cmd = "python $Bin/S144/script/sv_ca_reproter.py";
	&run_or_die($cmd);
	&show_log(&run_time($begin_time));
}

###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd Time :[$Time_End]\n\n";

###############Subs
sub show_log()
{
	my ($txt) = @_ ;
	my $time = time();
	my $Time = &sub_format_datetime(localtime($time));
	print "$Time:\t$txt\n" ;
	return ($time) ;
}

#Time calculation subroutine
sub sub_format_datetime {
	my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
	$wday = $yday = $isdst = 0;
	sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub run_time # &run_time($BEGIN);
{
	my ($t1)=@_;
	my $t=time()-$t1;
	my $line = "Total elapsed time : [".&sub_time($t)."]\n" ;
	return($line);
}

sub sub_time
{
	my ($T)=@_;chomp $T;
	my $s=0;my $m=0;my $h=0;
	if ($T>=3600) {
		my $h=int ($T/3600);
		my $a=$T%3600;
		if ($a>=60) {
			my $m=int($a/60);
			$s=$a%60;
			$T=$h."h\-".$m."m\-".$s."s";
		}else{
			$T=$h."h-"."0m\-".$a."s";
		}
	}else{
		if ($T>=60) {
			my $m=int($T/60);
			$s=$T%60;
			$T=$m."m\-".$s."s";
		}else{
			$T=$T."s";
		}
	}
	return ($T);
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

#### subs for main
#&get_parameters_from_config_and_check($config_file, \%hconfig, \%hdatabase, \%hsamples) ;
sub get_parameters_from_config_and_check()
{
	my ($config_file, $ahconfig, $ahdatabase, $ahsamples) = @_ ;
	# reading config file
	&reading_config_file($config_file, $ahconfig);
	# check config file
	&check_config_file($ahconfig, $ahsamples);

	return ;
}

# check config file's correctness
sub check_config_file()
{
	my ($ahconfig, $ahsamples) = @_ ;
	# ref
	if (!defined $ahconfig->{Ref}){
		print "ERROR:\tundefined Ref(reference file) in config file\n" ;
		exit (1) ;
	}
	if (!(-f $ahconfig->{Ref})){
		print "ERROR:\treference file not exist:", $ahconfig->{Ref}, "\n" ;
		exit (1) ;
	}
	if (!defined $ahconfig->{RefLen}){
		print "ERROR:\tundefined RefLen(reference length) in config file\n" ;
		exit (1);
	}
	# insert size
	if (!defined $ahconfig->{Ins}){
		print "ERROR:\tundefined Ins(insert size) in config file\n" ;
		exit (1) ;
	}
	# get reads
	for my $key (keys %{$ahconfig}){
		if ($key =~ /^(R\d+)-(\d)$/ || $key =~ /^(R\d+L\d+)-(\d)/){
			$ahsamples->{$1}->[$2 - 1] = $ahconfig->{$key} ;
		}
	}

	# check reads
	if (scalar (keys %{$ahsamples}) == 0){
		print "ERROR:\tundefined reads info in config file\n" ;
		exit (1);
	}

	return ;
}

# reading config file
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

#&process_dir();
sub process_dir()
{
	# make dir for each step
	mkdir "$outdir" ;
	mkdir "$outdir/Ref" ;
	mkdir "$outdir/Mapping" ;
	mkdir "$outdir/SNP" ;
	mkdir "$outdir/Result" ;

	return ;
}

sub prepare_ref()#没有用上
{
	my ($ahconfig, $ahsamples) = @_ ;
	my $ref = $ahconfig->{Ref} ;
	my $gff = $ahconfig->{Gff} ;
	my $ref_basename = basename($ref);
	mkdir "$outdir/Ref" ;
	my $link_ref = "$outdir/Ref/$ref_basename" ;
	my $refine_ref = "$Bin/Ref/ref.genome.fa" ;
	# refine ref
	if (!-f $refine_ref){
		# link ref
		if (!-f $link_ref){
			my $cmd = "ln -s $ref $link_ref" ;
			&run_or_die($cmd);
		}
		# refine ref
		my $cmd = "perl $Bin/Tools/refine_ref.pl -i $link_ref -o $refine_ref" ;
		&run_or_die($cmd);
	}
	# generate sample list file
	my $sample_list_file = "$outdir/Ref/sample.list" ;
	if (!-f $sample_list_file){
		&generate_sample_list_file($ahsamples, $sample_list_file);
	}
	# fa index
	if (!-f "$refine_ref.fai"){
		my $cmd = "samtools faidx $refine_ref" ;
		&run_or_die($cmd);
	}

	return ;
}

sub generate_sample_list_file()
{
	my ($ahsamples, $sample_list_file) = @_ ;
	open (OUT, ">$sample_list_file") || die "Can't creat $sample_list_file, $!\n" ;
	my %hflag = ();
	for my $sample (sort keys %{$ahsamples}){
		## for one sample has muli-library data, do a filter
		my $sample_id = $sample ;
		$sample_id = $1 if ($sample =~ /(R\d+)L\d+/);
		next if (defined $hflag{$sample_id}) ;
		$hflag{$sample_id} = 1;
		print OUT $sample_id,"\n" ;
	}
	close(OUT);

	return ;
}

sub prepare_rawdata()
{
	return ;
}

#############qsub
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
#	my ($shfile, $queue, $ass_maxproc) = @_ ;
#	$queue ||= 'general.q' ;
#	$ass_maxproc ||= $maxproc ;
#	if (`hostname` =~ /cluster/){
#		my $cmd = "perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
#		&run_or_die($cmd);
#	}
#	else{
#		my $cmd = "ssh cluster -Y perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
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
