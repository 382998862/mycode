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
if(!defined($opts{r}) || !defined($opts{p}) || !defined($opts{id}) || !defined($opts{db}) || !defined($opts{od}) || defined($opts{h}))
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
	Optional parameters:
		-ploidy      ploidy of species            [int]        optional [2]
		-t           thread number                [int]        optional [8]
		-m           max process for qsub         [int]        optional [25]
		-cpu         max cpu used in this process [int]        optional [100]
		-region      target region for GATK variant calling -L optional [/share/nas1/macc/Yincengceng/BED/Hg19.bed]
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
my $outprefix = $opts{p} ;
my $indir = $opts{id} ;
my $region = defined $opts{region} ? $opts{region} : "/share/nas1/macc/Yincengceng/BED/Hg19.bed";
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
my $picard_dir = "/share/nas2/genome/biosoft/picard-tools/current/" ;
my $gatk_dir = "/share/nas2/genome/biosoft/GATK/3.0-0/" ;
my $java_dir = "/share/nas1/dengdj/bin/Bio_soft/jre1.7.0_45/bin/" ;
my $bcftools_dir = "/share/nas2/genome/biosoft/samtools-0.1.18/bcftools/" ;
my $variant_file;
## Prepare
# reading config file
#&reading_config_file($configfile, \%hconfig) ;
# get bamfiles and index for fa and bams
&show_log("#------------ Start get ref and bam files, doing index...") ;
&prepare(\@bamfiles);
&show_log("#------------ Indexed done.") ;

## Duplicate marking
&show_log("#------------ Start Duplicate marking...") ;
my @dup_bam_files = &duplicate_marking(\@bamfiles);
&show_log("#------------ Duplicate marking done.") ;

## Local realignment
&show_log("#------------ Start Local realignment...") ;
my @realn_bam_files = &local_realignment(\@dup_bam_files);
&show_log("#------------ Local realignment done.") ;

## Base quality score recalibration(for deep coverage data(>=10x), this step is not needed.)
&show_log("#------------ Start Base quality score recalibration...") ;
my ($confidence_vcf, @bqsr_bam_files) = &base_quality_score_recalibration(\@realn_bam_files);
&show_log("#------------ Base quality score recalibration done.") ;

## Reduce bam file (not supported in 3.0)
#&show_log("#------------ Start reduce bam files...") ;
#my @reduced_bam_files = &reduce_bam_file(\@bqsr_bam_files);
#&show_log("#------------ Reduce bam files done.") ;

## Variant calling
#show_log("#------------ Start variants calling...") ;
#my $variant_file = &variant_calling(\@bqsr_bam_files);
#my $variant_file = &variant_calling(\@dup_bam_files);
#show_log("#------------ Variant calling done.") ;

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

## vVCF annotation
#&show_log("#------------ Start Annotation...");
#&SimpleAnno($variant_file);
#&show_log("#------------Annotation done.");

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
	&index_bam_file($abamfiles, $dir);

	return ;
}

## get bam files
sub get_bamfiles()
{
	my ($abamfiles, $dir) = @_ ;
	@{$abamfiles} = glob("$dir/*.bam");
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
	# creat target indel for realign
	my $intervals_file = "$dir/$outprefix.realn.intervals" ;
	#my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T RealignerTargetCreator -R $ref -nt $thread_num -o $intervals_file" ;
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T RealignerTargetCreator -R $ref -o $intervals_file" ;
	for my $bamfile (@{$abamfiles}){
		$cmd .= " -I $bamfile" ;
	}
	my $rtcsh = "$dir/$outprefix.rtc.sh";
	open (RTCSH, ">$rtcsh") || die "Can't creat $rctsh, $!\n";              ##RealignerTargetCreator qsub化
	print RCTSH $cmd;														##RealignerTargetCreator qsub化
	close RTCSH;															##RealignerTargetCreator qsub化
	&qsub($rtcsh);															##RealignerTargetCreator qsub化
	#&run_or_die($cmd) ;
	
	# realign for indels
	my $shfile = "$dir/$outprefix.realn.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		my $basename = basename($bamfile) ;
		(my $outfile = "$dir/$basename") =~ s/bam$/realn.bam/ ;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T IndelRealigner -R $ref -targetIntervals $intervals_file -o $outfile -I $bamfile \n" ;
		push @realnbamfiles, $outfile ;
	}
	close(SH);
	&qsub($shfile);

	return (@realnbamfiles) ;
}

## Base quality score recalibration
sub base_quality_score_recalibration()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/base_quality_score_recalibration" ;
	mkdir $dir ;
	# generate ref SNP resouce for BQSR
	my $confidence_vcf = &generate_confidence_SNP_resouce($abamfiles, $dir);

	# BQSR for bam files
	my @bqsr_bam_files = &BQSR_bam_files($abamfiles, $confidence_vcf, $dir);

	return ($confidence_vcf, @bqsr_bam_files);
}

# my $confidence_vcf = &generate_confidence_SNP_resouce($abamfiles, $dir);
# Generate confidence SNP for BQSR or VQSR by follow steps:
# 1. variants calling by GATK
# 2. variants calling by samtools
# 3. select concordance result from GATK and samtools
# 4. filter low quality SNPs
# 5. extract the PASS SNP result
# For now, just do 1~3 to get the confidence variants file.
sub generate_confidence_SNP_resouce()
{
	my ($abamfiles, $dir) = @_ ;
	# call variants use GATK
	my $gatk_vcf = "$dir/$outprefix.gatk_raw.vcf" ;
	&variants_calling_by_gatk($abamfiles, $gatk_vcf, $dir);
	# call variants use samtools
	my ($samtools_vcf) = &variants_calling_by_samtools($abamfiles, $dir);
	# select concordance result
	my $concordance_vcf = &select_concordance_result($gatk_vcf, $samtools_vcf, $dir);
	# filter low quality
	# my $filter_vcf = &variants_filter($concordance_vcf);
	# extract SNPs
	# my $confidence_vcf = &get_confidence_snp($filter_vcf);
	my $confidence_vcf = $concordance_vcf ;

	return ($confidence_vcf);
}

#$concordance_vcf = &hard_filter_for_vcf($gatk_vcf, $dir) ;
sub hard_filter_for_vcf()
{
	my ($gatk_vcf, $dir) = @_ ;

	return ;
}

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

# my $concordance_vcf = &select_concordance_result($gatk_vcf, $samtools_vcf, $dir);
sub select_concordance_result()
{
	my ($gatk_vcf, $samtools_vcf, $dir) = @_ ;
	my $concordance_vcf = "$dir/$outprefix.concordance_vcf" ;
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T SelectVariants -R $ref --variant $gatk_vcf --concordance $samtools_vcf -o $concordance_vcf" ;
	&run_or_die($cmd) ;

	return ($concordance_vcf);
}

# my $samtools_vcf = &variants_calling_by_samtools($abamfiles, $dir);
sub variants_calling_by_samtools()
{
	my ($abamfiles, $dir) = @_ ;
	my $samtools_vcf = "$dir/$outprefix.samtools_raw.vcf" ;
	my $cmd = "samtools mpileup -DSugf $ref" ;
	my $count = 0 ;
	for my $bamfile (@{$abamfiles}){
		$cmd .= " $bamfile" ;
		$count ++ ;
		last if ($count >= $max_sample_num);
	}
	$cmd .= " | $bcftools_dir/bcftools view -Ncvg - > $samtools_vcf" ;
	&run_or_die($cmd) ;
	(my $outfile = $samtools_vcf) =~ s/\.vcf$/.filter.vcf/ ;
	$cmd = "perl $Bin/samtools_vcf_filter.pl -i $samtools_vcf -o $outfile" ;
	&run_or_die($cmd) ;

	return ($outfile);
}

#-- &variants_calling_by_gatk($abamfiles, $gatk_vcf, $dir);
# Calling variants use GATK.
# Note that HaplotypeCaller only for diploid, and UnifiedGenotyper can use for all.
# Ploily must be specify. For pooled data, set to (Number of samples in each pool * Sample Ploidy).
#
sub variants_calling_by_gatk()
{
	my ($abamfiles, $gatk_vcf, $dir) = @_ ;
	my $sample_num = @{$abamfiles} ;
	#my ($gatk_thread, $qsub_proc) = &judge_cpu_allocation($sample_num, $chr_num, $thread_num);
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -Xmx20G -jar $gatk_dir/GenomeAnalysisTK.jar -T UnifiedGenotyper -L $region-R $ref -glm SNP -mte -nct $thread_num --sample_ploidy $ploidy" ;
	for my $bamfile (@{$abamfiles}){
		$cmd .= " -I $bamfile" ;
	}
	$cmd .= " --output_mode EMIT_VARIANTS_ONLY --dbsnp $db_vcf_file -o $gatk_vcf" ;
	&run_or_die($cmd) ;

	return;
}

#my $combine_gcvf_file = &combine_gvcf_files(\%hgvcf_files, $dir);
sub combine_gvcf_files()
{
	my ($ahgvcf_files, $dir) = @_ ;
	my $shfile = "$dir/$outprefix.combine.sample.gvcf.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	my @gvcf_files = ();
	for my $sample (sort keys %{$ahgvcf_files}){
		if (@{$ahgvcf_files->{$sample}} > 1){
			my $outfile = "$dir/$sample/$outprefix.$sample.gvcf" ;
			print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T CombineGVCFs -R $ref -o $outfile" ;
			for my $gvcf_file (@{$ahgvcf_files->{$sample}}){
				print SH " -V $gvcf_file" ;
			}
			print SH "\n" ;
			push @gvcf_files, $outfile ;
		}
		else{
			push @gvcf_files, $ahgvcf_files->{$sample}->[0] ;
		}
	}
	close(SH);
	&qsub($shfile, "general.q", $maxproc);
	my $combine_gcvf_file = "$dir/$outprefix.combine.all.gvcf" ;
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T CombineGVCFs -R $ref -o $combine_gcvf_file" ;
	for my $gvcf_file (@gvcf_files){
		$cmd .= " -V $gvcf_file" ;
	}
	&run_or_die($cmd);

	return($combine_gcvf_file);
}

#my ($gatk_thread, $qsub_proc) = &judge_cpu_allocation($sample_num, $chr_num, $thread_num);
sub judge_cpu_allocation()
{
	my ($sample_num, $chr_num, $thread_num) = @_ ;
	my ($gatk_thread, $qsub_proc);
	if ($sample_num*$chr_num > 25){
		$qsub_proc = 25 ;
		$gatk_thread = 4 ;
	}
	else{
		$qsub_proc = $sample_num * $chr_num ;
		$gatk_thread = int($maxcpu / $qsub_proc) ;
		$gatk_thread = 8 if ($gatk_thread > 8) ;
	}

	return ($gatk_thread, $qsub_proc);
}

#my @list_files = &get_chr_list_file($dir);
sub get_chr_list_file()
{
	my ($dir) = @_ ;
	my $fa_len_file = "$ref.len" ;
	if (!-f $fa_len_file){
		my $dir_name = dirname($ref);
		my $cmd = "/share/nas2/genome/biosoft/perl/5.18.2/bin/perl $Bin/../Tools/ref_GC_len.pl -ref $ref -od $dir_name" ;
		&run_or_die($cmd);
	}
	# get list file
	my $outfile = "$dir/$outprefix.chr_allocation" ;
	my $chr_num = 24 ;
	my $cmd = "perl $Bin/../Tools/distribute.pl -i $fa_len_file -o $outfile -n $chr_num" ;
	&run_or_die($cmd) ;
	
	my @list_files = ();
	for (my $i=1; $i<=$chr_num; $i++){
		push @list_files, "$outfile.$i.list" ;
	}

	return (@list_files);
}

# my @bqsr_bam_files = &BQSR_bam_files($abamfiles, $confidence_vcf, $dir);
sub BQSR_bam_files()
{
	my ($abamfiles, $confidence_vcf, $dir) = @_ ;
	my @bqsr_bam_files = ();
	# generate .grp(GATKReport) file for recalibration and plots
	my ($recal_data_table, $post_recal_data_table) = &generate_grp_file($abamfiles, $confidence_vcf, $dir);
	# Generate before/after plots
	&generate_recalibration_plots($recal_data_table, $post_recal_data_table, $dir);
	# BQSR for each bam files
	@bqsr_bam_files = &recalibration_for_each_sample($abamfiles, $recal_data_table, $dir);

	return (@bqsr_bam_files);
}

# my @bqsr_bam_files = &recalibration_for_each_sample($abamfiles, $recal_data_table, $dir);
sub recalibration_for_each_sample()
{
	my ($abamfiles, $recal_data_table, $dir) = @_ ;
	my @bqsr_bam_files = () ;
	my $shfile = "$dir/$outprefix.bqsr.sh" ;
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		my $basename = basename($bamfile) ;
		(my $outfile = "$dir/$basename") =~ s/bam$/racal.bam/ ;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T PrintReads -R $ref -BQSR $recal_data_table -I $bamfile -o $outfile \n" ;
		push @bqsr_bam_files, $outfile ;
	}
	close(SH);
	&qsub($shfile, "middle.q");

	return (@bqsr_bam_files);
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

# my ($recal_data_table, $post_recal_data_table) = &generate_grp_file($abamfiles, $confidence_vcf, $dir);
sub generate_grp_file()
{
	# init parameters
	my ($abamfiles, $confidence_vcf, $dir) = @_ ;
	my $recal_data_table = "$dir/$outprefix.recal_data.grp" ;
	my $post_recal_data_table = "$dir/$outprefix.post_recal_data.grp" ;
	# generate before grp
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T BaseRecalibrator -R $ref -knownSites $confidence_vcf -mte -nct $thread_num -o $recal_data_table" ;
	for my $bamfile (@{$abamfiles}){
		$cmd .= " -I $bamfile" ;
	}
	&run_or_die($cmd) ;
	# generate after grp
	$cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T BaseRecalibrator -R $ref -knownSites $confidence_vcf -mte -nct $thread_num -BQSR $recal_data_table -o $post_recal_data_table" ;
	for my $bamfile (@{$abamfiles}){
		$cmd .= " -I $bamfile" ;
	}
	&run_or_die($cmd) ;

	return ($recal_data_table, $post_recal_data_table);
}

## Reduce bam files
# Using ReduceReads on your BAM files will cut down the sizes to approximately 
# 1/100 of their original sizes. Also cuts the memory requirements, I/O burden, 
# and CPU costs of downstream tools significantly (10x or more).
# Note that ReduceReads is not meant to be run on multiple samples at once.
# If you plan on merging your sample bam files, you should run ReduceReads 
# on individual samples before doing so.
# my @reduced_bam_files = &reduce_bam_file(\@bqsr_bam_files);
sub reduce_bam_file()
{
	# init parameters
	my ($abamfiles) = @_ ;
	my @reduced_bam_files = ();
	my $dir = "$outdir/reduce_bam_file" ;
	mkdir "$dir" ;
	my $shfile = "$dir/$outprefix.reduce_bam.sh" ;
	# reduce bam file
	open (SH, ">$shfile") || die "Can't creat $shfile, $!\n" ;
	for my $bamfile (@{$abamfiles}){
		my $basename = basename($bamfile);
		(my $outfile = "$dir/$basename") =~ s/bam$/reduced.bam/ ;
		print SH "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T ReduceReads -R $ref -I $bamfile -o $outfile \n" ;
		push @reduced_bam_files, $outfile ;
	}
	close(SH);
	&qsub($shfile);

	return (@reduced_bam_files);
}

## Variants calling
# Calling SNP and small indels use HaplotypeCaller(diploid) or UnifiedGenotyper(other ploidy or pooled data)
# &variant_calling(\@reduce_bam_file);
sub variant_calling()
{
	my ($abamfiles) = @_ ;
	my $dir = "$outdir/variant_calling" ;
	mkdir "$dir" ;
	my $gatk_vcf = "$dir/$outprefix.formal.vcf" ;
	&variants_calling_by_gatk($abamfiles, $gatk_vcf, $dir);
	#&run_or_die($cmd) ;

	return ($gatk_vcf);
}

## add rs number
#&add_rs_number($variant_file);
sub add_rs_number()
{
	my ($variant_file) = @_ ;
	my $dir = "$outdir/result" ;
	mkdir "$dir" ;
	my $basename = basename($variant_file) ;
	(my $outfile = "$dir/$basename") =~ s/.vcf$/.final.vcf/ ;
	my $cmd = "perl $Bin/add_rs_number.pl -i $variant_file -dbsnp $db_vcf_file -o $outfile" ;
	&run_or_die($cmd);

	return ;
}


## Variants quality score recalibration
# Note:
# This tool is expecting thousands of variant sites in order to achieve decent modeling
# with the Gaussian mixture model. Whole exome call sets work well, but anything smaller 
# than that scale might run into difficulties. 
# In our testing we've found that in order to achieve the best exome results one needs to 
# use an exome SNP and/or indel callset with at least 30 samples. 
# 
# The SNP and indel need processed separately.
# 
# &variant_quality_score_recalibration($variant_file, $confidence_vcf);
sub variant_quality_score_recalibration()
{
	my ($variant_file, $confidence_vcf) = @_ ;
	my $dir = "$outdir/variant_quality_score_recalibration" ;
	mkdir $dir ;
	# separate SNP and Indel into two file
	my ($snp_vcf_file, $indel_vcf_file) = &extract_SNP_and_Indel($variant_file, $dir);

	# VQSR for SNP
	my $vqsr_snp_vcf = &vqsr($snp_vcf_file, $confidence_vcf, "SNP");

	# VQSR for Indel
	my $vqsr_indel_vcf = &vqsr($indel_vcf_file, $confidence_vcf, "INDEL");

	return ($vqsr_snp_vcf, $vqsr_indel_vcf);
}

# my ($snp_vcf_file, $indel_vcf_file) = &extract_SNP_and_Indel($variant_file, $dir);
sub extract_SNP_and_Indel()
{
	my ($variant_file, $dir) = @_ ;
	my $basename = basename($variant_file) ;
	(my $snp_vcf_file = "$dir/$basename") =~ s/vcf$/snp.vcf/ ;
	(my $indel_vcf_file = "$dir/$basename") =~ s/vcf$/indel.vcf/ ;
	#my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T SelectVariants -R $ref -V $variant_file -selectType SNP -o $snp_vcf_file -nt $thread_num" ;
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T SelectVariants -R $ref -V $variant_file -selectType SNP -o $snp_vcf_file" ;
	&run_or_die($cmd) ;
	#$cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T SelectVariants -R $ref -V $variant_file -selectType INDEL -o $indel_vcf_file -nt $thread_num" ;
	$cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T SelectVariants -R $ref -V $variant_file -selectType INDEL -o $indel_vcf_file" ;
	&run_or_die($cmd) ;

	return ($snp_vcf_file, $indel_vcf_file);
}

#- vqsr for variants
# my $vqsr_vcf = &vqsr($vcf_file, $confidence_vcf, "SNP/INDEL");
sub vqsr()
{
	my ($vcf_file, $confidence_vcf, $type) = @_ ;
	(my $vqsr_vcf = $vcf_file) =~ s/vcf$/vqsr.vcf/ ;

	# Build the recalibration model use VariantRecalibrator
	my ($recal_file, $tranches_file, $rscript_file) = &build_recalibration_model($vcf_file, $confidence_vcf, $type, $ref);
	
	# Apply the desired level of recalibration to the variants use ApplyRecalibration
	$vqsr_vcf = &apply_recalibration($recal_file, $tranches_file, $vcf_file, $type, $ref);

	return ($vqsr_vcf);
}

# my ($recal_file, $tranches_file, $rscript_file) = &build_recalibration_model($vcf_file, $confidence_vcf, $type, $ref);
sub build_recalibration_model()
{
	my ($vcf_file, $confidence_vcf, $type, $ref) = @_ ;
	(my $recal_file = $vcf_file) =~ s/vcf$/recal/ ;
	(my $tranches_file = $vcf_file) =~ s/vcf$/tranches/ ;
	(my $rscript_file = $vcf_file) =~ s/vcf$/plots.R/ ;
	#my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T VariantRecalibrator -R $ref -input $vcf_file -nt $thread_num" ;
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T VariantRecalibrator -R $ref -input $vcf_file" ;  # avoid error of "open too many files"
	$cmd .= " -recalFile $recal_file -tranchesFile $tranches_file -rscriptFile $rscript_file" ;
	$cmd .= " --TStranche 90.0 --TStranche 93.0 --TStranche 95.0 --TStranche 97.0 --TStranche 99.0 --TStranche 99.9 --TStranche 100.0" ;
	if ($type eq "SNP"){
		$cmd .= " -mode SNP -resource:hapmap,known=false,training=true,truth=true,prior=10.0 $confidence_vcf" ;
		#$cmd .= " -an DP -an QD -an FS -an MQRankSum -an ReadPosRankSum" ;
		#$cmd .= " -an DP -an QD -an MQRankSum -an ReadPosRankSum" ; # do not add -an FS for occur error when testing arabidopsis, but sometimes not
		$cmd .= " -an DP -an QD -an MQRankSum -an ReadPosRankSum -an FS" ; # it seems like the order has influence
	}
	else{
		# for indel, use "--maxGaussians 4" by its little number
		$cmd .= " -mode INDEL -resource:mills,known=false,training=true,truth=true,prior=10.0 $confidence_vcf" ;
		$cmd .= " -an DP -an FS -an MQRankSum -an ReadPosRankSum --maxGaussians 4 --minNumBadVariants 1000" ;
	}
	&run_or_die($cmd) ;

	return ($recal_file, $tranches_file, $rscript_file) ;
}

# my $vqsr_vcf = &apply_recalibration($recal_file, $tranches_file, $vcf_file, $type, $ref);
sub apply_recalibration()
{
	my ($recal_file, $tranches_file, $vcf_file, $type, $ref) = @_ ;
	(my $vqsr_vcf = $vcf_file) =~ s/vcf$/vqsr.vcf/ ;
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T ApplyRecalibration -R $ref -input $vcf_file -o $vqsr_vcf" ;
	#$cmd .= " --ts_filter_level 99.9 -recalFile $recal_file -tranchesFile $tranches_file -nt $thread_num" ;
	$cmd .= " --ts_filter_level 90 -recalFile $recal_file -tranchesFile $tranches_file" ;
	if ($type eq "SNP"){
		$cmd .= " -mode SNP" ;
	}
	else{
		$cmd .= " -mode INDEL" ;
	}
	&run_or_die($cmd) ;

	return ($vqsr_vcf);
}

## Filter variants
# my ($filter_snp_vcf, $filter_indel_vcf) = &filter_variants($vqsr_snp_vcf, $vqsr_indel_vcf);
sub filter_variants()
{
	my ($vqsr_snp_vcf, $vqsr_indel_vcf) = @_ ;
	my $dir = "$outdir/filter_variants" ;
	mkdir "$dir" ;
	my $snp_basename = basename($vqsr_snp_vcf);
	my $indel_basename = basename($vqsr_indel_vcf);
	(my $filter_snp_vcf = "$dir/$snp_basename") =~ s/vcf$/filter.vcf/ ;
	(my $filter_indel_vcf = "$dir/$indel_basename") =~ s/vcf$/filter.vcf/ ;
	# filter SNP
	my $cmd = "awk \'(\$7 != \".\" && \$7 !~ /VQSR/){print \$0}\'" ;
	$cmd .= " $vqsr_snp_vcf > $filter_snp_vcf" ;
	&run_or_die($cmd) ;
	# filter INDEL
	$cmd = "awk \'(\$7 != \".\" && \$7 !~ /VQSR/){print \$0}\'" ;
	#$cmd = "awk \'(\$7 != \".\" && \$7 != VQSRTrancheINDEL97.00to99.00 && \$7 != VQSRTrancheINDEL99.00to99.90 && \$7 != VQSRTrancheINDEL99.90to100.00){print \$0}\'" ;
	$cmd .= " $vqsr_indel_vcf > $filter_indel_vcf" ;
	&run_or_die($cmd) ;

	return ($filter_snp_vcf, $filter_indel_vcf);
}

## Variants evalution
#&variants_evalution($filter_snp_vcf, $filter_indel_vcf);
sub variants_evalution()
{
	my ($filter_snp_vcf, $filter_indel_vcf) = @_ ;
	(my $snp_eval_file = $filter_snp_vcf) =~ s/vcf$/eval.gatkreport/ ;
	(my $indel_eval_file = $filter_indel_vcf) =~ s/vcf$/eval.gatkreport/ ;
	# for SNP
	#my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T VariantEval -R $ref -eval:allsamples $filter_snp_vcf -o $snp_eval_file -nt $thread_num" ;
	my $cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T VariantEval -R $ref -eval:allsamples $filter_snp_vcf -o $snp_eval_file" ;
	$cmd .= " -noEV -EV CountVariants -EV TiTvVariantEvaluator -EV VariantSummary" ;
	&run_or_die($cmd) ;
	# for INDEL
	#$cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T VariantEval -R $ref -eval:allsamples $filter_indel_vcf -o $indel_eval_file -nt $thread_num" ;
	$cmd = "$java_dir/java -Djava.io.tmpdir=$tmp_dir -jar $gatk_dir/GenomeAnalysisTK.jar -T VariantEval -R $ref -eval:allsamples $filter_indel_vcf -o $indel_eval_file" ;
	$cmd .= " -noEV -EV CountVariants -EV IndelLengthHistogram -EV IndelSummary -EV VariantSummary" ;
	&run_or_die($cmd) ;
	
	return ;
}

##my ($final_snp_vcf, $final_indel_vcf) = &link_result($filter_snp_vcf, $filter_indel_vcf);
sub link_result()
{
	my ($filter_snp_vcf, $filter_indel_vcf) = @_ ;
	my $dir = "$outdir/result" ;
	mkdir $dir ;
	my $cmd = "ln -s $filter_snp_vcf $filter_indel_vcf $dir/" ;
	&run_or_die($cmd);

	my $snp_basename = basename($filter_snp_vcf) ;
	my $final_snp_vcf = "$dir/$snp_basename" ;
	my $indel_basename = basename($filter_indel_vcf) ;
	my $final_indel_vcf = "$dir/$indel_basename" ;

	return ($final_snp_vcf, $final_indel_vcf);
}

## Convert vcf to snplist
#&convert_vcf_to_snplist($snp_vcf);
sub convert_vcf_to_snplist()
{
	my ($vcf_file) = @_ ;
	(my $outfile = $vcf_file) =~ s/vcf$/snp/ ;
	my $cmd = "perl $Bin/vcf_to_snplist_v1.2.pl -ref 1 -i $vcf_file -o $outfile" ;
	&run_or_die($cmd) ;

	return($outfile) ;
}

#&static_snp_result($snp_list_file);
sub static_snp_result()
{
	my ($snp_list_file) = @_ ;
	(my $outfile = $snp_list_file) =~ s/$/.stat/ ;
	my $cmd = "perl $Bin/snp_stat.pl -i $snp_list_file -o $outfile" ;
	&run_or_die($cmd);

	return ;
}

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

sub SimpleAnno($variant_file)
{
mkdir "$outdir/Anno";
print "perl $Bin/SNPAnnotation_v1.2.pl -i $variant_file -od $outdir/Anno -o $outprefix -r $ref -s Human -mode SNP\n";
system("perl $Bin/SNPAnnotation_v1.2.pl -i $variant_file -od $outdir/Anno -o $outprefix -r $ref -s Human -mode SNP");

open(IN, "$outdir/Anno/$outprefix.formal.anno.gatk.vcf") or die "no such file";
open(OUT, ">$outdir/Anno/$outprefix.anno.gatk.simple.vcf") or die "cannot creat file";
print OUT "Chromosome\t","Position\t", "dbSNP\t","Reference\t","Alternative\t","Quality\t","Symbol\t", "Effect\t","Genotype\n";
while(<IN>){
	if ($_ !~ /^#/) {
		my $eff;
		my $sym;
		my %hash;
		my $gt;
		my $genotype;
		my @line = split(/\t/, $_);
		my @anno = split(/;/, $line[7]);
		#print $anno[1],"\n";
		foreach my $item (@anno) {
			#print $item,"\n";
			my ($i ,$j) = split (/=/, $item);
			$hash{$i} = $j;
			}
		#print %hash;		
		my @key = keys(%hash);
		#print $key[1],"\t";
		if(grep /SNPEFF_EFFECT/, @key){
			$eff = $hash{"SNPEFF_EFFECT"};
		}
		if(grep /SNPEFF_GENE_NAME/, @key){
			$sym = $hash{"SNPEFF_GENE_NAME"};
		}else{
			$sym = "";
		}
		#print $sym,"\t",$eff,"\n";
		
		my @info = split(/:/, $line[9]);
		$gt = $info[0];
		if ($gt eq "1/1") {
			$genotype = "Homozygous";
		}else{
			$genotype = "Heterozygous";
		}	
		my @record = (@line[0..5], $sym, $eff,$genotype,);
		print OUT join("\t", @record),"\n";
	}
}
close (IN);
close (OUT);
}
