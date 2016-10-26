#!/usr/bin/perl -w
# 
# Copyright (c) BIO_MARK 2014
# Writer:         Dengdj <dengdj@biomarker.com.cn>
# Program Date:   2014
# Modifier:       Dengdj <dengdj@biomarker.com.cn>
# Last Modified:  2014.
my $ver="1.5.0";

use strict;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

######################请在写程序之前，一定写明时间、程序用途、参数说明；每次修改程序时，也请做好注释工作

my %opts;
GetOptions(\%opts,"r=s","od=s","id=s","region=s","ploidy=s","p=s","t=s","cpu=s","db=s","m=s","h" );

#&help()if(defined $opts{h});
if(!defined($opts{r}) || !defined($opts{p}) || !defined($opts{id}) || !defined($opts{db}) || !defined($opts{od}) || !defined($opts{region}) || defined($opts{h}))
{
	print <<"	Usage End.";
	Description:
		
		Version: $ver
		v1.4:	Use GATK 3.0 for SNP calling. HaplotypeCaller for 2 ploidy and UnifiedGenotyper for others.
		v1.5:	Support multi-library for one sample.
		     	Bugfixed in multiploid or haploid vcf result transform to snp format.
		     	Optimizing of SNP calling in UnifiedGenotyper and samtools.

	Usage:
	Forced parameters:
		-od          outdir                       <dir>        must be given
		-p           outfile prefix               <str>        must be given
		-id          indir of bam file            <dir>        must be given
		-r           reference file               <file>       must be given
		-db          dbsnp vcf file               <file>       must be given
		-region		 bed file of target region    <file>       must be given
	Optional parameters:
		-ploidy      ploidy of species            [int]        optional [2]
		-t           thread number                [int]        optional [8]
		-m           max process for qsub         [int]        optional [25]
		-cpu         max cpu used in this process [int]        optional [100]
		-h           Help document

	Usage End.

	exit(1);
}

###############Time
my $Time_Start;
$Time_Start = sub_format_datetime(localtime(time()));
print "\nStart Time :[$Time_Start]\n\n";
################

## init parameters
my $ref = $opts{r} ;
$ref = &ABSOLUTE_DIR($ref);
my $outdir = $opts{od} ;
mkdir $outdir ;
$outdir = &ABSOLUTE_DIR($outdir) ;
my $region = $opts{region};
my $outprefix = $opts{p} ;
my $indir = $opts{id} ;
$indir = &ABSOLUTE_DIR($indir) ;
my $db_vcf_file = $opts{db} ;
$db_vcf_file = &ABSOLUTE_DIR($db_vcf_file);
my $ploidy = defined $opts{ploidy} ? $opts{ploidy} : 2 ;
my $thread_num = defined $opts{t} ? $opts{t} : 8 ;
my $maxproc = defined $opts{m} ? $opts{m} : 25 ;
my $maxcpu = defined $opts{cpu} ? $opts{cpu} : 100 ;
my $max_sample_num = 5 ;  ### this is for samtools calling snp, if there are more than 5 sample, only use 5 sample for samtools.
my $tmp_dir = "$outdir/tmp" ;
mkdir $tmp_dir ;
my @bamfiles = () ;
my $picard_dir = "/share/nas2/genome/biosoft/picard-tools/current" ;
my $gatk_dir="/share/nas2/genome/biosoft/GATK/3.0-0";
my $java_dir="/share/nas1/dengdj/bin/Bio_soft/jre1.7.0_45/bin" ;
my $bcftools_dir = "/share/nas2/genome/biosoft/samtools-0.1.18/bcftools/" ;
#my $variant_file;
## Prepare
# reading config file
#&reading_config_file($configfile, \%hconfig) ;
# get bamfiles and index for fa and bams
&show_log("#------------ Start get ref and bam files, doing index...") ;
&prepare(\@bamfiles);
&show_log("#------------ Indexed done.") ;

## Duplicate marking
#&show_log("#------------ Start Duplicate marking...") ;
#my @dup_bam_files = &duplicate_marking(\@bamfiles);
#&show_log("#------------ Duplicate marking done.") ;

## Local realignment
#&show_log("#------------ Start Local realignment...") ;
#my @realn_bam_files = &local_realignment(\@bamfiles);
#&show_log("#------------ Local realignment done.") ;

## Base quality score recalibration(for deep coverage data(>=10x), this step is not needed.)
&show_log("#------------ Start Base quality score recalibration...") ;
my (@bqsr_bam_files) = &base_quality_score_recalibration(\@bamfiles);   ###!!!
&show_log("#------------ Base quality score recalibration done.") ;

## Reduce bam file (not supported in 3.0)
#&show_log("#------------ Start reduce bam files...") ;
#my @reduced_bam_files = &reduce_bam_file(\@bqsr_bam_files);                                     ###!!
#&show_log("#------------ Reduce bam files done.") ;

## Variant calling
&show_log("#------------ Start variants calling...") ;
my @variant_files = &variant_calling(\@bqsr_bam_files);
#my $variant_file = &variant_calling(\@dup_bam_files);
&show_log("#------------ Variant calling done.") ;

## Link result
#&add_rs_number($variant_file);

## Variant quality score recalibration
#&show_log("#------------ Start Variant quality score recalibration...") ;
#my ($vqsr_snp_vcf, $vqsr_indel_vcf) = &variant_quality_score_recalibration($variant_file, $confidence_vcf);
#&show_log("#------------ Variant quality score recalibration done.") ;

## Filter variants
#&show_log("#------------ Start Filter variants...") ;
#my ($filter_snp_vcf, $filter_indel_vcf) = &filter_variants($vqsr_snp_vcf, $vqsr_indel_vcf);
#&show_log("#------------ Filter variants done.") ;

## Variants evalution
#&show_log("#------------ Start variants evalution...") ;
#&variants_evalution($filter_snp_vcf, $filter_indel_vcf);
#&show_log("#------------ Variants evalution done.") ;

## Link result
#my ($final_snp_vcf, $final_indel_vcf) = &link_result($filter_snp_vcf, $filter_indel_vcf);

## Convert vcf to snp list file
#&show_log("#------------ Start convert vcf to snp...") ;
#my $snp_list_file = &convert_vcf_to_snplist($final_snp_vcf) ;
#&show_log("#------------ Convert vcf to snp done.") ;

## stat snp result
#&show_log("#------------ Start Statistic snp result...");
#&static_snp_result($snp_list_file);
#&show_log("#------------ Statistic snp result done.");

### Variant Hard filter  ~~~
&show_log("#------------ Filtering variants with hard filter...");
my @variant_files = &hard_filter(\@variant_files);
&show_log("#------------ Filtering done...");

## VCF annotation            ~~~
&show_log("#------------ Start Annotation...");
my @annotation = &Annotate(\@variant_files);
&show_log("#------------Annotation done.");

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


## &prepare(\@bamfiles);
sub prepare()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/prepare" ;
	mkdir $dir ;
	# get bam files
	&get_bamfiles($abamfiles, $indir);
	# check ref file is exist, and end with .fa or .fasta
	&check_ref_file();
	# index reference
	&index_fa();
	# index bam files
	#&index_bam_file($abamfiles, $dir);

	return ;
}

## get bam files
sub get_bamfiles()
{
	my ($abamfiles, $dir) = @_ ;
	@{$abamfiles} = glob("$dir/$outprefix.*.bam");
	if (scalar (@{$abamfiles}) == 0){
		print "No bam file found, please check\n" ;
		exit (1);
	}

	return ;
}

## &check_ref_file();
sub check_ref_file()
{
	if (!-f $ref){
		print "Reference file: $ref not exist!\n" ;
		exit (1);
	}
	if ($ref !~ /\.fa$/ && $ref !~ /\.fasta$/){
		print "Reference file: $ref must end with .fa or .fasta\n" ;
		exit (1);
	}
	return ;
}

## index ref fa
sub index_fa()
{
	my ($abamfiles) = @_ ;
	# index for ref
	if (!-f "$ref.fai"){
		my $cmd = "samtools faidx $ref" ;
		&run_or_die($cmd);
	}
	(my $dict_file = $ref) =~ s/\.fa$|\.fasta$/.dict/ ;
	if (!-f "$dict_file"){
		my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $picard_dir/CreateSequenceDictionary.jar REFERENCE=$ref OUTPUT=$dict_file" ;
		&run_or_die($cmd);
	}
	my $fa_length_file = "$ref.len" ;
	my $dir = dirname($ref);
	if (!-f $fa_length_file){
		my $cmd = "/share/nas2/genome/biosoft/perl/5.18.2/bin/perl $Bin/../Tools/ref_GC_len.pl -ref $ref -od $dir" ;
		&run_or_die($cmd);
	}
	&show_log("index reference done.") ;

	return ;
}

## index for bam
sub index_bam_file()
{
	my ($abamfiles, $dir) = @_ ;
	my $shfile = "$dir/$outprefix.bam.idx.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		(my $tmpfile = $bamfile) =~ s/.bam$/.bai/ ;
		if (!-f $tmpfile && !-f "$bamfile.bai"){
			print SH "samtools index $bamfile $tmpfile\n" ;
		}
	}
	close(SH);
	&qsub($shfile);

	return ;
}

#&get_sample_bam_files($abamfiles, \%hsamples_bam);
sub get_sample_bam_files()
{
	my ($abamfiles, $ahsamples_bam) = @_ ;
	for my $bamfile (@{$abamfiles}){
		my $basename = basename($bamfile);
		my $sample_id = $basename ;
		if ($basename =~ /\.(R\d+)\.sort.bam$/ || $basename =~ /\.(R\d+)L\d+\.sort.bam$/){
			$sample_id = $1 ;
		}
		push @{$ahsamples_bam->{$sample_id}}, $bamfile ;
	}
	return ;
}

## Duplicate marking
sub duplicate_marking()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/duplicate_marking" ;
	mkdir $dir ;
	my @dupbamfiles = ();
	my $shfile = "$dir/$outprefix.dedup.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	my %hsamples_bam = ();
	&get_sample_bam_files($abamfiles, \%hsamples_bam);
	for my $sample (sort keys %hsamples_bam){
		my $basename = "$outprefix.$sample.dedup.bam" ;
		my $outfile = "$dir/$basename" ;
		(my $metrics_file = "$dir/$basename") =~ s/bam$/metrics/ ;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $picard_dir/MarkDuplicates.jar MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=512 VALIDATION_STRINGENCY=LENIENT" ;
		for my $bamfile (@{$hsamples_bam{$sample}}){
			print SH " INPUT=$bamfile" ;
		}
		print SH " OUTPUT=$outfile METRICS_FILE=$metrics_file\n" ;
		push @dupbamfiles, $outfile ;
	}
	close(SH) ;
	&qsub($shfile);
	&index_bam_file(\@dupbamfiles, $dir);

	return (@dupbamfiles) ;
}

## Local realignment
sub local_realignment()
{
	# init parameter
	my ($abamfiles) = @_ ;
	my @realnbamfiles = ();
	my $dir = "$outdir/local_realignment" ;
	mkdir "$dir" ;
	my $interval_file = "$dir/$outprefix.interval.sh" ;
	open (SH, ">$interval_file") || die "Can't creat $interval_file, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		my $basename = basename($bamfile) ;
		(my $intervals_file = "$dir/$basename") =~ s/bam$/realn.intervals/;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T RealignerTargetCreator -I $bamfile -R $ref -o $intervals_file -L $region \n" ;
	}
	&qsub($interval_file);
	close(SH);

	my $realn_file = "$dir/$outprefix.realn.sh" ;
	open (SH, ">$realn_file") || die "Can't creat $realn_file, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		my $basename = basename($bamfile) ;
		(my $intervals_file = "$dir/$basename") =~ s/bam$/realn.intervals/;
		(my $outfile = "$dir/$basename") =~ s/bam$/realn.bam/ ;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T IndelRealigner -I $bamfile -R $ref -L $region -targetIntervals $intervals_file -o $outfile  \n" ;
		push @realnbamfiles, $outfile ;
	}
	close(SH);
	&qsub($realn_file);

	return (@realnbamfiles) ;
}

## Base quality score recalibration
sub base_quality_score_recalibration()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/base_quality_score_recalibration" ;
	mkdir $dir ;
	# BQSR for bam files
	my @bqsr_bam_files = &BQSR_bam_files($abamfiles, $db_vcf_file, $dir);

	return (@bqsr_bam_files);
}

# my @bqsr_bam_files = &BQSR_bam_files($abamfiles, $db_vcf_file, $dir);
sub BQSR_bam_files()
{
	my ($abamfiles, $db_vcf_file, $dir) = @_ ;
	my @bqsr_bam_files = ();
	# generate .grp(GATKReport) file for recalibration and plots
	my (@recal_data_table) = &generate_grp_file($abamfiles, $db_vcf_file, $dir);
	# my ($recal_data_table, $post_recal_data_table) = &generate_grp_file($abamfiles, $db_vcf_file, $dir);
	# Generate before/after plots
	# &generate_recalibration_plots($recal_data_table, $post_recal_data_table, $dir);
	# BQSR for each bam files
	@bqsr_bam_files = &recalibration_for_each_sample($abamfiles, \@recal_data_table, $dir);

	return (@bqsr_bam_files);
}
sub generate_grp_file()
{
	# init parameters
	my ($abamfiles, $db_vcf_file, $dir) = @_ ;
	my @recal_data_table;
	# generate before grp
	my $shfile = "$dir/$outprefix.realn.recal.sh";
	open(SH, ">$shfile") || die "cannot create recal sh!!\n";
	for my $bamfile (@{$abamfiles}) {
		my $basename = basename($bamfile);
		(my $outfile = "$dir/$basename") =~ s/bam$/recal.table/;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T BaseRecalibrator -R $ref -I $bamfile -L $region -knownSites $db_vcf_file -mte -nct $thread_num -o $outfile \n";
		push(@recal_data_table, $outfile);
	}
	close(SH);
	&qsub($shfile);
	return (@recal_data_table);
}
# &generate_recalibration_plots($recal_data_table, $post_recal_data_table, $dir);
sub generate_recalibration_plots()
{
	my ($recal_data_table, $post_recal_data_table, $dir) = @_ ;
	my $plotfile = "$dir/$outprefix.recalibration_plots.pdf" ;
	#my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T AnalyzeCovariates -R $ref" .
	#          " -before $recal_data_table -after $post_recal_data_table -plots $plotfile" ;
	#&run_or_die($cmd) ; # do not use this for Rscript versions not match
	### ToDo
	#print "$cmd\n" ;
	#print `$cmd` ;
	return ;
}

# my @bqsr_bam_files = &recalibration_for_each_sample($abamfiles, $recal_data_table, $dir);
sub recalibration_for_each_sample()
{
	my ($abamfiles, $recal_data_table, $dir) = @_ ;
	my @bqsr_bam_files = () ;
	my $shfile = "$dir/$outprefix.bqsr.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	my @bams = @{$abamfiles};
	my @tables = @{$recal_data_table};
	my $len = @bams;
	foreach my $i (0..($len-1)){
		my $basename = basename($bams[$i]) ;
		(my $outfile = "$dir/$basename") =~ s/bam$/recal.bam/ ;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T PrintReads -R $ref -L $region -BQSR $tables[$i] -I $bams[$i] -o $outfile \n" ;
		push (@bqsr_bam_files, $outfile);
	}
	close(SH);
	&qsub($shfile, "middle.q");
	return (@bqsr_bam_files);
}

# my ($recal_data_table, $post_recal_data_table) = &generate_grp_file($abamfiles, $db_vcf_file, $dir);

# my $confidence_vcf = &generate_confidence_SNP_resouce($abamfiles, $dir);
# Generate confidence SNP for BQSR or VQSR by follow steps:
# 1. variants calling by GATK
# 2. variants calling by samtools
# 3. select concordance result from GATK and samtools
# 4. filter low quality SNPs
# 5. extract the PASS SNP result
# For now, just do 1~3 to get the confidence variants file.
#$concordance_vcf = &hard_filter_for_vcf($gatk_vcf, $dir) ;

#&run_cmds_use_qsub($dir, \@cmds);
sub run_cmds_use_qsub()
{
	my ($dir, $acmds) = @_ ;
	my $shfile = "$dir/$outprefix.merge_cmds.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $cmd (@{$acmds}){
		print SH $cmd, "\n" ;
	}
	close(SH) ;
	&qsub($shfile) ;

	return ;
}

#-- &variants_calling_by_gatk($abamfiles, $gatk_vcf, $dir);
# Calling variants use GATK.
# Note that HaplotypeCaller only for diploid, and UnifiedGenotyper can use for all.
# Ploily must be specify. For pooled data, set to (Number of samples in each pool * Sample Ploidy).
#
## Variants calling
# Calling SNP and small indels use HaplotypeCaller(diploid) or UnifiedGenotyper(other ploidy or pooled data)
# &variant_calling(\@reduce_bam_file);
sub variant_calling()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/variant_calling";
	my $reassemble_dir = "$outdir/reassemble";
	mkdir "$dir" ;
	mkdir "$reassemble_dir";
	#my $gatk_vcf = "$dir/$outprefix.formal.vcf" ;
	my @gatk_vcf_files = &variants_calling_by_gatk($abamfiles, $dir, $reassemble_dir);
	#&run_or_die($cmd) ;
	return (@gatk_vcf_files);
}
sub variants_calling_by_gatk()
{
	my ($abamfiles, $dir, $reassemble_dir) = @_ ;
	my $sample_num = @{$abamfiles} ;
	my @gatk_vcf_files;
	#my ($gatk_thread, $qsub_proc) = &judge_cpu_allocation($sample_num, $chr_num, $thread_num);
	my $shfile = "$dir/$outprefix.ug.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ; 
	for my $bamfile (@{$abamfiles}) {
		my $basename = basename($bamfile);
		(my $gatk_vcf = "$dir/$basename") =~ s/bam$/ug.vcf/;
		(my $reassemble_bam = "$reassemble_dir/$basename") =~ s/bam$/reassemble.bam/;
		my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -Xmx20G -jar $gatk_dir/GenomeAnalysisTK.jar -T UnifiedGenotyper -I $bamfile -L $region -R $ref -nct $thread_num -dt NONE --dbsnp $db_vcf_file -o $gatk_vcf \n" ;
		print SH $cmd;
		push (@gatk_vcf_files, $gatk_vcf)
	}
	close(SH);
	&qsub($shfile);
	return (@gatk_vcf_files);
}

###Hard filter for variants filtering
sub hard_filter()
{
	my ($gatk_vcf) = @_;
	my $dir = "$outdir/Filtered";
	my @filter_files;
	mkdir $dir;
	my $shfile = "$dir/$outprefix.hardfilter.sh";
	open (SH, ">$shfile");
	for my $vcf (@{$gatk_vcf}) {
		my $basename = basename($vcf);
		(my $filter =  "$dir/$basename") =~ s/vcf/filtered.vcf/;
		print SH "$java_dir/java -jar $gatk_dir/GenomeAnalysisTK.jar -T SelectVariants -R $ref --variant $vcf -o $filter -select \'DP > 20\'", "\n";
		push (@filter_files, $filter);
	}
	close(SH);
	&qsub($shfile);
	return (@filter_files);
}


#### Annotate vcf files
sub Annotate()
{
	my ($vcffiles) = @_;
	mkdir "$outdir/Anno";
	print @{$vcffiles},"~~~~~~~~~~~~~~~~~\n";
	#my $shfile = "$outdir/Anno/$outprefix.anno.sh";
	#open (SH, ">$shfile");
	for my $vcf (@{$vcffiles}) {
		my $basename = basename($vcf);
		(my $outp = $basename) =~ s/vcf$//;
		system ("perl $Bin/SNPAnnotation_v1.2.pl -i $vcf -od $outdir/Anno -o $outp -r $ref -s Human -mode SNP \n");
	}
	#close(SH);
	#&qsub($shfile);
	
	&show_log("#------------ Simplify the VCF files");
	for my $vcf (@{$vcffiles}) {
		my $basename = basename($vcf);
		(my $annofile = $basename) =~ s/vcf/anno.gatk.vcf/;
		(my $outp = $basename) =~ s/.vcf$//;
		print "perl $Bin/Simplify.pl -i $outdir/Anno/$annofile -od $outdir/Anno -p $outp","\n";
		system("perl $Bin/Simplify.pl -i $outdir/Anno/$annofile -od $outdir/Anno -p $outp");
	}
	&show_log("#------------ Simplify done");
	system ("rm $outdir/Anno/*.anno.vcf");
	system ("rm $outdir/Anno/*.anno.vcf.idx");
	system ("rm $outdir/Anno/snpEff_genes.txt");
	system ("rm $outdir/Anno/snpEff_summary.html");
	system ("rm -rf $outdir/Anno/result");
	system ("rm -rf $outdir/Anno/anno_stat");
	system ("rm -rf $outdir/Anno/sh_dir");
}


############################################################################

## show log
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
	my ($shfile, $queue, $ass_maxproc) = @_ ;
	$queue ||= 'general.q' ;
	$ass_maxproc ||= $maxproc ;
	if (`hostname` =~ /cluster/){
		my $cmd = "perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}
	else{
		my $cmd = "ssh cluster -Y perl /share/nas2/genome/bin/qsub-sge.pl --maxproc $ass_maxproc --queue $queue --resource vf=15G --reqsub $shfile --independent" ;
		&run_or_die($cmd);
	}
	return ;
}

