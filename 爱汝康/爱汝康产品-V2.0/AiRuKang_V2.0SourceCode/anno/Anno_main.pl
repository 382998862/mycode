#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin $Script);
use Cwd qw(abs_path getcwd);


my ($step,$outdir,$sample_name,$prefix);
GetOptions(
		"Step:s" => \$step,
		"Outdir:s" => \$outdir,
		"Sample:s" => \$sample_name,
		"Prefix:s" => \$prefix,
		"help|?" => \&USAGE,
		) or &USAGE;
&USAGE unless ($step and $outdir and $sample_name and $prefix);
# my $cmd = "perl $Bin/anno/Anno_main.pl -Step 1,2,3 -Outdir  $outdir -Sample $sample_name -Prefix  $outprefix "

my %sample;
my $sample_path = "$outdir"."/SNP/variant_calling/"."$prefix"."\.$sample_name"."\.dedup.realn.recal.ug.vcf";
print $sample_path;
$sample{$sample_name} = $sample_path;

# my $cmd = "perl $Bin/anno/Anno_main.pl -Step 1,2,3 -Outdir  $outdir -Sample $sample_name -Prefix  $outprefix ";
=a
my $cfgfile = $ARGV[0];
my $step = $ARGV[1];
open(CFG,$cfgfile)||die"Where's the config ?\n";
my %sample;
while(<CFG>){
	chomp;
	s/\r//;
	if ($_ =~ /^R/) {
		my ($sam_name,$sam_path) = split/\t/,$_;
		$sample{$sam_name} = $sam_path;
	}
}
close CFG;
#print Dumper %sample;
=cut

mkdir ("Annotation",0755) unless (-e "Annotation" && -d "Annotaiton");
mkdir ("Annotation/work_sh",0755) unless (-e "Annotation/work_sh" && -d "Annotation/work_sh") ;
my $dir_0 = $outdir;  #20160809
my $dir = "$dir_0"."/Annotation";
my $dir_SNP = "$dir_0"."/SNP";

my %Step;
foreach my $key (split /,/,$step) {
    my $num = $key;
    $Step{$key} = $num;
}

if ( exists $Step{1} ) {
	mkdir ("Annotation/Annovar",0755) unless (-e "Annotation/Annovar" && -d "Annotation/Annovar");
	my $list_format = "Annotation/Annovar/format.list";
	open(my $STEP1_SHELL,'>',"$dir/work_sh/step1_annovar1.sh")||die"$!";
	open(my $STEP1_LIST,'>',"$list_format");  #可以省略
	foreach my $key (sort keys %sample) {
		print $STEP1_SHELL "perl /share/nas1/tengwj/Pipeline/Programs/annovar/convert2annovar.pl -format vcf4 $sample{$key} > $dir/Annovar/$key.avinput\n";  #### 20160603
		print $STEP1_LIST "$dir/Annovar/$sample{$key}.avinput\n";
	}
	close $STEP1_SHELL;
#	&qsub("$dir/work_sh/step1_annovar1.sh");  # 应当存到一个变量里
	&sh("$dir/work_sh/step1_annovar1.sh");

	open(my $STEP2_SHELL,'>',"$dir/work_sh/step1_annovar2.sh")||die"$!";
	foreach my $key (sort keys %sample) {
		print $STEP2_SHELL " cd $dir/Annovar/ \n perl /share/nas1/tengwj/Pipeline/Programs/annovar/annotate_variation.pl -out $key -build hg19 $dir/Annovar/$key.avinput /share/nas1/tengwj/Pipeline/Programs/annovar/humandb/ \n";
	}
	close $STEP2_SHELL;
#	&qsub("$dir/work_sh/step1_annovar2.sh");
	&sh("$dir/work_sh/step1_annovar2.sh");

#	`mv $dir/work_sh/step1_annovar2.sh.*.qsub/R* $dir/Annovar `;


#	open(my $STEP3_SHELL,'>',"work_sh/step1_annovar3.sh")||die"$!";
#	foreach my $key (sort keys %sample) {
#		print $STEP3_SHELL "perl /home/tengwj/nas1/NEW/Pipeline/Tools/vcf-xls.pl -i $sample{$key}  -o $dir/Annovar/$key.xls \n";
#	}
#	close $STEP3_SHELL;
#	&qsub("$dir/work_sh/step1_annovar3.sh");
#	&sh("$dir/work_sh/step1_annovar3.sh");



	open(my $STEP4_SHELL,'>',"$dir/work_sh/step1_annovar4.sh")||die"$!";
	foreach my $key (sort keys %sample) {
#		print "perl $Bin/Noname2.pl \n";
		print $STEP4_SHELL "perl $Bin/Noname2_new.pl $dir/Annovar/$key.variant_function $dir/Annovar/$key.exonic_variant_function  $dir/Annovar/$key.annovar.out \n";
	}
	close $STEP4_SHELL;
#	&qsub("$dir/work_sh/step1_annovar4.sh");
	&sh("$dir/work_sh/step1_annovar4.sh");

}


if (exists $Step{2}) {
	mkdir ("Annotation/Clinvar",0755) unless (-e "Annotation/Clinvar" && -d "Annotation/Clinvar");
	open(my $STEP5_SHELL,'>',"$dir/work_sh/step2_clinvar.sh")||die"$!";
	foreach my $key (sort keys %sample) {
		print $STEP5_SHELL "perl $Bin/3_new_new.pl $dir/Annovar/$key.annovar.out $dir/Clinvar/$key.clinvar.out \n";
	}
	close $STEP5_SHELL;
#	&qsub("$dir/work_sh/step2_clinvar.sh");
	&sh("$dir/work_sh/step2_clinvar.sh");
}


if (exists $Step{3} ) {
	mkdir ("Annotation/Result",0755) unless (-e "Annotation/Result" && -d "Annotation/Result");
	open(my $STEP6_SHELL,'>',"$dir/work_sh/step3_check.sh")||die"$!";
	foreach my $key (sort keys %sample) {
		print $STEP6_SHELL "perl $Bin/deal_new.pl $dir/Clinvar/$key.clinvar.out $dir/Result/$prefix.$key.result.xls \n";
	}
	close $STEP6_SHELL;
#	&qsub("$dir/work_sh/step3_check.sh");
	&sh("$dir/work_sh/step3_check.sh");
}



if (exists $Step{4} ) {
	open(my $STEP7_SHELL,'>',"$dir/work_sh/step4_unscramble.sh")||die"$!";
	foreach my $key (sort keys %sample) {
		print $STEP7_SHELL " python $Bin/../Tools/mut-position.py -d 1 -i $dir_SNP/variant_calling/$prefix.$key.dedup.realn.recal.mpileup.out  -o $dir/Result/$prefix.$key.dedup.realn.recal.mutpos.out \n perl $Bin/hotspot.pl -result_file $dir/Result/$prefix.$key.result.xls -mutpos_file $dir/Result/$prefix.$key.dedup.realn.recal.mutpos.out -vcf_file  $dir_SNP/variant_calling/$prefix.$key.dedup.realn.recal.ug.vcf > $dir/Result/$prefix.$key.hotspot.out   \n perl $Bin/generate_result.pl -i  $dir/Result/$prefix.$key.hotspot.out  -o  $dir/Result/$prefix.$key.scramble.final.xls \n";
	}
	close $$STEP7_SHELL;
#	&sh("$dir/work_sh/step4_unscramble.sh");
	&sh("$dir/work_sh/step4_unscramble.sh");
	
	
	
	
	
	
}

=a
}	
		print `perl /home/xudd/workdir/Programs/annovar/annotate_variation.pl -out $_ -build hg19 $_.avinput /home/xudd/workdir/Programs/annovar/humandb/`;
}

=a
	print "\nConvert format start :\n";
	`perl /share/nas1/xudd/Programs/annovar/convert2annovar.pl -format vcf4 $input > $output`;
	print "\nConvert format end :\n ANNOVAR start:\n";
	`perl /home/xudd/workdir/Programs/annovar/annotate_variation.pl -out ARK_063.R01.sort.recal.ug.filtered -build hg19 ARK_063.R01.sort.recal.ug.filtered.avinput /home/xudd/workdir/Programs/annovar/humandb/`;
	print "\nConvert format end :\n ANNOVAR finish!\n";
}


if ($step ==2 ) {
	` perl  /share/nas1/tengwj/NEW/Pipeline/Tools/vcf-xls.pl -i ARK_063.R01.sort.recal.ug.filtered.vcf -o ARK_063.R01.sort.recal.ug.filtered.xls`
	`perl Noname2.pl`

}

if ($step ==3 ) {
	`perl /dbsnp`

}
sub MKDIR { # &MKDIR($out_dir);
	my ($dir)=@_;
	rmdir($dir) if(-d $dir);
	mkdir($dir) if(!-d $dir);
}


=cut


sub qsub {
	my ($file) = @_;
#	print "$file\t111\n";


	if (`hostname` =~ /cluster/) {
		my $qsub = "perl $Bin/qsub-sge.pl --line 5 --queue general.q --resource vf=0.5G --maxproc 100  --reqsub   --independent $file ";
		print "Command: $qsub\n";
		`$qsub`;
	}
	else {
		my $qsub = "ssh  cluster -Y perl $Bin/qsub-sge.pl --line 5 --queue general.q --resource vf=0.5G --maxproc 100  --reqsub   --independent $file ";
		print "Command: $qsub\n";
		`$qsub`;
	}
	return ;
}


sub sh {
	my ($file) = @_;
	my $cmd = "sh $file";
	`$cmd`;
	return;
}


sub USAGE {
	my $usage=<<"USAGE";
------------------------------------------------------------------------------------------------
		
		-Step
		-Outdir
		-Sample
		-Prefix
		-help
------------------------------------------------------------------------------------------------
USAGE
	print $usage;
	exit;
}


