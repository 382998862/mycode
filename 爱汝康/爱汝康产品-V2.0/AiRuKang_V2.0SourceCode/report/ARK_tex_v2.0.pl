#!usr/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;
#use Encode;

=a
my $file_para =  $ARGV[1];
my $file_result = $ARGV[0];
my $dir_output = $ARGV[2];  
#my $file_result = "testresult";
=cut

my ($file_result,$file_para,$dir_output);
GetOptions(
		"Result_file:s" => \$file_result,
		"Parameter_file:s" => \$file_para,
		"Output_directory:s" => \$dir_output,
		"help|?" => \&USAGE,
)or &USAGE;
&USAGE unless ($file_result and $file_para and $dir_output);

open(FIN1,$file_result)||die"$!";
my $clinsign = 0;
while(<FIN1>){
	chomp;
	next if (/^Chrom/);
	my @line = split/\t/,$_;
	if ( $line[35] =~ /pathogenic/i) {  # 0718+8
		$clinsign = 1;
	}
}
close FIN1;
print"$clinsign\n";


open(FIN,$file_para)||die"$!";
open(FOUT,">$dir_output/Outfile.txt");
print "OutputDirectory: $dir_output/Outfile.txt\n";
my %con;
my ($name,$age,$gender,$sampletype,$sampleno,$date1,$date2,$report1,$report2,$report3,$report4);
while(<FIN>){
	chomp;
	next if (/^#/);
	s/_/\\_/;
	if (/^Name/) {
		$name = (split/\s+/,$_)[0];
		$con{$name} = (split/\s+/,$_)[1];
	}
	if (/^Age/) {
		$age = (split/\s+/,$_)[0];
		$con{$age} = (split/\s+/,$_)[1];
	}
	if (/^Gender/) {
		$gender = (split/\s+/,$_)[0];
		$con{$gender} = (split/\s+/,$_)[1];
	}
	if (/^SampleType/) {
		$sampletype = (split/\s+/,$_)[0];
		$con{$sampletype} = (split/\s+/,$_)[1];
	}
	if (/^SampleNO/) {
		$sampleno = (split/\s+/,$_)[0];
		$con{$sampleno} = (split/\s+/,$_)[1];
	}
	if (/^Date1/) {
		$date1 = (split/\s+/,$_)[0];
		$con{$date1} = (split/\s+/,$_)[1];
	}
	if (/^Date2/) {
		$date2 = (split/\s+/,$_)[0];
		$con{$date2} = (split/\s+/,$_)[1];
	}
	if ($clinsign == 0) {      # adjust value
		if (/^reportA1/) {
			$report1 = (split/\s+/,$_)[0];
			$con{$report1} = (split/\s+/,$_)[1];
		}
		if (/^reportA2/) {
			$report2 = (split/\s+/,$_)[0];
			$con{$report2} = (split/\s+/,$_)[1];
		}
		if (/^reportA3/) {
			$report3 = (split/\s+/,$_)[0];
			$con{$report3} = (split/\s+/,$_)[1];
		}
		if (/^reportA4/) {
			$report4 = (split/\s+/,$_)[0];
			$con{$report4} = (split/\s+/,$_)[1];
		}
	}
	if ($clinsign == 1) {    # adjust value
		if (/^reportB1/) {
			$report1 = (split/\s+/,$_)[0];
			$con{$report1} = (split/\s+/,$_)[1];
		}
		if (/^reportB2/) {
			$report2 = (split/\s+/,$_)[0];
			$con{$report2} = (split/\s+/,$_)[1];
		}
		if (/^reportB3/) {
			$report3 = (split/\s+/,$_)[0];
			$con{$report3} = (split/\s+/,$_)[1];
		}
		if (/^reportB4/) {
			$report4 = (split/\s+/,$_)[0];
			$con{$report4} = (split/\s+/,$_)[1];
		}					
	}
}

#print Dumper %con;
close FIN;

foreach my $key (sort keys %con){
	print "$key\t$con{$key}\n";
	print FOUT "$key\t$con{$key}\n";
}
my %aa;

open(FIN1,$file_result)||die"$!";
my $h = 1;
my $i = 1;
my %table;
my %talbe_all;
my $form;
while(<FIN1>){
	chomp;
#	s/\r//;
	s/_/\\_/g;
	next if (/^Chrom/);
	my @line = split/\t/,$_;
	if ($line[0] eq "阳性") {  #0718 阳性	
		my $h = $h++;
		my $col_9 = $h;
		$talbe_all{$h}{9} = $col_9;   #Num
		$talbe_all{$h}{10} = $line[8];   #0718 +8 Chrom
		$talbe_all{$h}{11} = $line[9];	 #0718 +8 Position
		$talbe_all{$h}{12} = $line[10];  #0718 +8 Ref
		$talbe_all{$h}{13} = $line[11];  #0718 +8 Variant
		$talbe_all{$h}{14} = $line[19];  #0718 +8 allele.
		$talbe_all{$h}{15} = $line[12];  #0718 +8 region.
		my $col_16;
		if ( $line[5] =~ /\(/ ) {
		    ($col_16) = $line[13] =~ /(\S+)\(/; #0718 +8 gene
		}
		else {
			$col_16 = $line[13];
		}
		$talbe_all{$h}{16} = $col_16;   # gene
		$talbe_all{$h}{17} = $line[22]; # 0718 +8 synonymous
		$talbe_all{$h}{18} = $line[39]; # 0718 +8 RsNumber
		if ($line[0] eq "阳性" && $line[1] eq "数据库" && $line[2] eq "Pass"){   # 0718阳性+数据库+pass
			my $i = $i++;
			my $col_1 = $i;	
			$table{$i}{1} = $col_1;
			my $col_2;
			if ( $line[13] =~ /\(/ ) {   #0718 +8  gene
				($col_2) = $line[13] =~ /(\S+)\(/;
			}
			else {
				$col_2 = $line[13];
			}
			$table{$i}{2} = $col_2;  #0718  gene
			my $col_3 = $line[8].":".$line[9];  # 0718 +8  chr13:32890572
			$table{$i}{3} = $col_3 ;  # 0718  chr13:32890572
			my ($col_4) = $line[32] =~ /c.\S+\d+(\S+)/;   #modifide  #0718 +8
			$table{$i}{4} = $col_4;
			my $col_5;
			if ($line[33] =~ /^p/){  # 0718 +8
			    $col_5 = $line[32]." (".$line[33].")";  # 0718 +8
			}
			else{
			    $col_5 = $line[32]; # 0718 +8
			}
		          $table{$i}{5} = $col_5;
			my $col_6 ;
			if ( $line[19] eq "hom" ) {   # 0718 +8
				$col_6 = "纯合";
			}
			elsif ( $line[19] eq "het" ) {  # 0718 +8
				$col_6 = "杂合";
			}
			$table{$i}{6} = $col_6;
			my $col_7 ;
			if ( $line[34] =~ /^nonsynonymous/ ) {  # 0718 +8
				$col_7 = "非同义突变";
			}
			elsif ($line[34] =~ /^synonymous/) {   # 0718 +8
				$col_7 = "同义突变";
			}
			else {
				$col_7 = "其他突变";
			}
			$table{$i}{7} = $col_7;
			my $col_8;
			if ($line[35] =~ /pathogenic/i ) {  # 0718 +8
			   $col_8 = "有害突变"; 
		          }
		          elsif ( $line[35] =~ /^Benign;_risk_factor$/) {  # 0718 +8
			   $col_8 = "未知突变";  
		          }
		          elsif ($line[35] =~ /benign/i) {
			   $col_8 = "无害突变"; 
		          }
			else{
			   $col_8 = "未知突变"; 
		          }
			$table{$i}{8} = $col_8;
			$table{$i}{9} = $line[32];  #for decode  # 0718 +8
		          if ( $line[33] =~ /^p/ ) {	#for decode  # 0718 +8
			    $table{$i}{10} = $line[33];  # 0718 +8
			}
			else {
			    $table{$i}{10} = "null";
			}
			if ( $line[41]  =~ /\d+/ ){ #for decode     if ($line[33] =~ /\d+/)  # 0718 +8
			    $table{$i}{11} = "http://www.ncbi.nlm.nih.gov/clinvar/variation/$line[41]/";  #need added;  # 0718 +8
			}
			else {
			    $table{$i}{11} = "http://www.ncbi.nlm.nih.gov/clinvar/?term=$line[39]";  # 0718 +8
			}
			if ($i %2 == 0) {
			    $form .= "$col_1 \& \\sl{$col_2} \& $col_3 \& $col_4 \& $col_5 \& $col_6 \& $col_7 \& $col_8\\\\\\\\\n";
			}
			else {
			    $form .= "\n\\rowcolor{linecolor1}\n$col_1 \& \\sl{$col_2} \& $col_3 \& $col_4 \& $col_5 \& $col_6 \& $col_7 \& $col_8\\\\\\\\\n";
			}
			print FOUT "$col_1\t$col_2\t$col_3\t$col_4\t$col_5\t$col_6\t$col_7\t$col_8\n";	

		}
		
	}
	
}
close FIN1;		
#print Dumper %table;


# 该变异位于--基因上，DNA编码序列上--，--，其变异为--变异，根据权威数据库记载，该变异为--变异。
#for (my $j=1;$j<$i;$j++) {
#		print FOUT "$j.$table{$j}{2} $table{$j}{5} $table{$j}{7} \n 该变异位于$table{$j}{2}基因上，DNA编码序列变异为$table{$j}{4}，引起蛋白序列变异为$table{$j}{5}，其变异为$table{$j}{6}变异。根据权威数据库记载该变异为$table{$j}{8}。\n\n";
#	}

my $decode;
for (my $j=1;$j<$i;$j++) {
     my $de_5_fw;
     if ($table{$j}{9} =~ /\>/){
        my ($ref_c) = $table{$j}{9} =~ /([A-Z])>[A-Z]/;
        my ($alt_c) = $table{$j}{9} =~ /[A-Z]>([A-Z])/;
        $de_5_fw = "DNA编码序列上的碱基由$ref_c变异为$alt_c，";
     }

     elsif ($table{$j}{9} =~ /del/) {
        if ($table{$j}{9} =~ /del\w+ins/) {
	  $de_5_fw = "DNA编码序列上发生插入缺失变异，";
        }
        else {
	  $de_5_fw = "DNA编码序列上发生缺失变异，";
        }
     }
     elsif ( $table{$j}{9} =~ /dup([A-Z]+)^/) {
         my $base = $1;
         $de_5_fw = "DNA编码序列上碱基$base发生重复，";
     }
     elsif ($table{$j}{9} =~ /ins/){
         $de_5_fw = "DNA编码序列上发生插入变异，";
     }
     my $de_5_bw;
     if ($table{$j}{10} =~ /null/){   # empty 
         $de_5_bw = "";
     }
     elsif ($table{$j}{10} =~ /fs$/) {  # p.Tyr1661Leufs
         $de_5_bw = "引起蛋白序列的移码变异，";
     }
     elsif ($table{$j}{10} =~ /=$/) {   # p.Ser1659=
         $de_5_bw = "蛋白序列未发生改变，";
     }
     elsif ($table{$j}{10} =~ /p.([A-Z][a-z][a-z])\d+([A-Z][a-z][a-z])/ ) { # p.Pro1660Leu
         my $ref_p = $1;
         my $alt_p = $2;
         $de_5_bw = "引起蛋白序列上由".&aachn($ref_p)."变异为".&aachn($alt_p)."，";
     }
     $decode .= "\\item {{\\sl{$table{$j}{2}}} $table{$j}{5} $table{$j}{7}}\n \\\\ 该变异位于{\\sl{$table{$j}{2}}}基因上,$de_5_fw $de_5_bw其变异为$table{$j}{6}变异。根据权威数据库记载该变异为$table{$j}{8}\\footnote{$table{$j}{11}}。\\\n";
}



my $table_all_end;
for (my $g=1;$g<$h;$g++) {
		my $mttyp;
		if ($talbe_all{$g}{17} =~ /^nonsynonymous/) {
		    $mttyp = "nSNV";
		}
		elsif ($talbe_all{$g}{17} =~ /^synonymous/) {
		    $mttyp = "sSNV";
		}
		else {
		    $mttyp = "-";
		}
		if ($g % 2 == 0){
		    $table_all_end .= "$talbe_all{$g}{9} \& $talbe_all{$g}{10} \& $talbe_all{$g}{11} \& $talbe_all{$g}{12} \& $talbe_all{$g}{13} \& $talbe_all{$g}{14} \& $talbe_all{$g}{15} \& $talbe_all{$g}{16} \& $mttyp \& $talbe_all{$g}{18} \\\\ \n  ";
		}
		else {
		    $table_all_end .= "\n\\rowcolor{linecolor2}\n $talbe_all{$g}{9} \& $talbe_all{$g}{10} \& $talbe_all{$g}{11} \& $talbe_all{$g}{12} \& $talbe_all{$g}{13} \& $talbe_all{$g}{14}\& $talbe_all{$g}{15} \& $talbe_all{$g}{16} \& $mttyp \& $talbe_all{$g}{18} \\\\ ";
		}
	}
# $talbe_all{$g}{9}
#2 & chr1 & 45797505 & C & G & Het & exonic & {\sl{MUTYH}} & nonsynonymous SNV & rs3219489\\

print FOUT ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$decode\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.\n\n\n";



#print  ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$form\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n\n";	
close FOUT;		


open (FOUT2,">$dir_output/test.tex");
print "Test\n";
print FOUT2 
"
\\documentclass[a4paper]{article}
\\usepackage{pdfpages}
\\usepackage{wallpaper}
\\usepackage{colortbl}
\\usepackage{longtable}
\\usepackage{enumitem}
\\usepackage{booktabs}
\\usepackage{geometry}
\\usepackage{array}
\\usepackage[labelsep=space]{caption}
\\usepackage{ctexcap}


\\setCJKfamilyfont{hydsj}{汉仪大宋简}
\\newcommand{\\hydsj}{\\CJKfamily{hydsj}}

\\setCJKfamilyfont{fzdbs}{FZDaBiaoSong-B06S}
\\newcommand{\\fzdbs}{\\CJKfamily{fzdbs}}

\\newcommand{\\fur}{\\fontsize{14pt}{\\baselineskip}\\selectfont}
\\newcommand{\\thr}{\\fontsize{15.75pt}{\\baselineskip}\\selectfont}
\\newcommand{\\two}{\\fontsize{21pt}{\\baselineskip}\\selectfont}
\\newcommand{\\twom}{\\fontsize{18pt}{\\baselineskip}\\selectfont}
\\newcommand{\\six}{\\fontsize{7.875pt}{\\baselineskip}\\selectfont}

\\definecolor{tabcolor}{rgb}{0.905,0.010,0.213}
\\definecolor{linecolor1}{rgb}{0.98,0.86,0.91}
\\definecolor{linecolor2}{rgb}{0.99,0.91,0.95}

\\renewcommand\\contentsname{\\centering{\\textcolor[rgb]{0.905,0.090,0.213}{目\\quad 录}}}

\\geometry{top=4cm, bottom=2.5cm, left=2.2cm, right=2cm}
\\renewcommand{\\thetable}{{}}
\\renewcommand{\\tablename}{{}}


\\setlength{\\labelsep}{0.25em}
\\setlength{\\itemsep}{0.25ex}
\\setlength{\\topsep}{0.25ex}


\\CTEXsetup[number={},format={\\two\\fzdbs},indent={-3pt},afterskip={15pt}]{section}
\\CTEXsetup[number={},format={\\twom\\fzdbs},afterskip={12pt}]{subsection}

\\pagestyle{plain}

\\begin{document}

\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/tengwj/Pipeline/AiRuKang/report/Cover.pdf}
\\null
\\thispagestyle{empty}
\\clearpage


\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/tengwj/Pipeline/AiRuKang/report/Inner.pdf}
\\vspace*{1.5cm}
\\begin{center}
\\setlength{\\extrarowheight}{13pt}
\\begin{tabular}{p{4.5cm}p{5.5cm}}
		\\fzdbs{\\twom{姓\\qquad 名：}}&\\fzdbs{\\twom{$con{$name}}} \\\\  %%%%%
		\\fzdbs{\\twom{年\\qquad 龄：}}&\\fzdbs{\\twom{$con{$age}}} \\\\  %%%%%
		\\fzdbs{\\twom{性\\qquad 别：}}&\\twom\\fzdbs{{$con{$gender}}} \\\\   %%%%%
        &\\\\
        &\\\\
		\\fzdbs{\\twom{样本类型：}}&\\fzdbs{\\twom{$con{$sampletype}}} \\\\  %%%%%
        \\fzdbs{\\twom{样本编号：}}&\\fzdbs{\\twom{$con{$sampleno}}} \\\\   %%%%%
		\\fzdbs{\\twom{收样日期：}}&\\fzdbs{\\twom{$con{$date1}}}\\\\   %%%%%
		\\fzdbs{\\twom{报告日期：}}&\\fzdbs{\\twom{$con{$date2}}} \\\\   %%%%%

\\end{tabular}
\\end{center}
%\\thispagestyle{empty}


\\clearpage

\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/tengwj/Pipeline/AiRuKang/report/Inner.pdf}
\\tableofcontents
\\clearpage

\\TileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/tengwj/Pipeline/AiRuKang/report/Inner.pdf}
\\section{检测结果}

%通过对您的{\\sl{ATM、BARD1、BRCA1、BRCA2、BRIP1、CDH1、CHEK2、MSH6、MRE11A、MUTYH、NBN、NF1、PALB2、PTEN、RAD50、RAD51C、STK11、TP53 }}18个基因进行测序，$con{$report1}。综合以上结果， \\textbf{$con{$report2}。}\\\\     %%%%%
通过对您的{\\sl{BRCA1、BRCA2 }}2个基因进行测序，$con{$report1}。综合以上结果， \\textbf{$con{$report2}。}\\\\

\\subsection{基因变异列表}


{\\six\\begin{longtable}{p{1.4cm}p{1cm}p{2cm}p{1.5cm}p{2cm}p{1cm}p{1.4cm}p{1.4cm}}
\\arrayrulecolor{tabcolor}
\\toprule[1.4pt]
\\textbf{位点编号} & \\textbf{基因} & \\textbf{突变位置} & \\textbf{DNA变异} & \\textbf{变异结果} & \\textbf{纯合/杂合} & \\textbf{变异类型} & \\textbf{临床意义}\\\\
\\midrule
\\endhead
$form

\\bottomrule
\\caption{\\six{*无害变异是指已有研究表明此位点的此种变异在现有的文献及数据库中注明未见增加乳腺癌的风险。}} 
\\end{longtable}}

本报告中所列信息是根据您的样本的基因突变在多个知名公共数据库及文献中查询的结果。随着科学研究的进行，某些变异的临床意义有可能发生改变。完整变异情况请看附表。

\\subsection{报告解读}
\\begin{enumerate}

$decode

\\end{enumerate}

\\clearpage

\\section{健康管理}
\\subsection{生活建议}
鉴于您的乳腺癌遗传风险为$con{$report3}，如下方案供您参考：  %%%%%

$con{$report4}


\\subsection{筛查建议}
参考中国抗癌协会乳腺癌诊治指南与规范（2015版）筛查建议如下表\\footnote{中国抗癌协会乳腺癌专业委员会. 中国抗癌协会乳腺癌诊治指南与规范(2013版).中国癌症杂志.2013,23(8):637-84}：
{\\six\\begin{longtable}{p{2.5cm}p{6cm}}
\\arrayrulecolor{tabcolor}
\\toprule[1.4pt]
\\textbf{年龄} & \\textbf{筛查方式}\\\\
\\midrule
\\rowcolor{linecolor2}
20～39周岁 & 不推荐对非高危人群进行乳腺筛查。\\\\
40～49周岁 & 适合机会性筛查\\footnote{机会性筛查是妇女个体主动或自愿到提供乳腺筛查的医疗机构进行相关检查。}。\\\\
  & 每年1次乳腺X线检查。\\\\
  & 推荐与临床体检联合。\\\\
  & 对致密型乳腺\\footnote{致密型乳腺：乳腺组织非常致密，纤维腺体多于75\\%，可能会掩盖其中的病灶。}。\\\\
\\rowcolor{linecolor2}
  50～69周岁 & 适合机会性筛查和人群普查\\footnote{群体普查是社区或单位实体有组织地为适龄妇女提供乳腺筛查。}。\\\\
\\rowcolor{linecolor2}
  & 每1～2年1次乳腺X线检查。\\\\
\\rowcolor{linecolor2}
  & 推荐与临床体检联合。\\\\
\\rowcolor{linecolor2}
  & 对致密型乳腺推荐与B超检查联合。\\\\
  70周岁或以上 & 适合机会性筛查。\\\\
  & 每2年1次乳腺X线检查。\\\\
  & 推荐与临床体检联合。\\\\
  & 对致密型乳腺推荐与B超检查联合。\\\\
\\bottomrule
\\end{longtable}}
\\clearpage

\\section{乳腺癌知识}
\\subsection{乳腺癌概况}
乳腺癌是危害女性身心健康的恶性肿瘤。欧美国家乳腺癌发病率占女性恶性肿瘤的25\\%-30\\%。近年来中国的乳腺癌发病率上升趋势明显，成为增长最快的国家之一，并且与发达国家相比，其死亡率也相对较高。在全球范围内，每年中国乳腺癌新发病例占据全世界新诊断乳腺癌病例的12.2\\%，死于乳腺癌的人数占据全世界乳腺癌死亡人数的9.6\\% \\footnote{Fan L，et al. Breast cancer in China..Lanncet  Oncol 2014 Jun;15(7):e279-89}。
\\subsection{乳腺癌的组织学分类}
乳腺癌有多种分型方法，目前国内多采用以下病理分型：

1. 非浸润性癌 包括导管内癌（癌细胞未突破导管壁基底膜）、小叶原位癌（癌细胞未突破末梢乳管或腺泡基底膜）及乳头湿疹样乳腺癌（伴发浸润性癌者，不在此列）。此型属早期，预后较好。

2. 浸润性特殊癌 包括乳头状癌、髓样癌（伴大量淋巴细胞浸润）、小管癌（高分化腺癌）、腺样囊性癌、黏液腺癌、顶泌汗腺样癌、鳞状细胞癌等。此型分化一般较高，预后尚好。

3. 浸润性非特殊癌 包括浸润性小叶癌、浸润性导管癌、硬癌、髓样癌（无大量淋巴细胞浸润）、单纯癌、腺癌等。此型一般分化低，预后较上述类型差，且是乳腺癌中最常见的类型，占80\\%，但判断预后尚需结合疾病分期等因素。


\\subsection{乳腺癌的症状}

乳腺癌的主要临床症状有：

1. 乳腺肿块。多为无痛性、进行性生长。质地多为实性、较硬。

2. 乳头溢液。乳头溢液可因多种乳腺疾病而引发，性状多种多样，可为血性、血清样、水样、浆液性、脓性或乳汁样等，以乳汁样、水样和浆液性较为常见。

3. 乳头乳晕改变。包括乳头回缩、乳头糜烂等。

4. 皮肤改变。包括皮肤粘连凹陷、皮肤红肿、皮肤浅表静脉曲张、皮肤水肿、皮肤溃疡、皮肤卫星结节等。

5. 乳房疼痛。疼痛不是乳腺肿瘤常见的症状，但有个别病例显示早期乳腺癌肿块部位可出现疼痛。

6. 区域淋巴结肿大。乳腺癌最多见的淋巴结转移部位为同侧腋窝淋巴结，其次为同侧乳内淋巴结。表现为转移部位淋巴结肿大、质硬，起初肿大的淋巴结可以推动，最后相互融合、固定。

\\subsection{乳腺癌的危险因素}
1.遗传

家族史一直被认为是重要危险因素之一。流行病学研究表明，乳腺癌患者亲属中乳腺癌总体发病率较高。研究显示，具有一级亲属乳腺癌家族史的女性罹患乳腺癌的危险性是乳腺癌家族史阴性女性的1．74倍\\footnote{ Kilfoy BA，Zhang Y，Shu XO et a1．Family history of malignancies and risk of breast cancer：prospective data from the Shanghai womeng health study[J]．Cancer Causes Control，2008，19 (10)：1139}。乳腺癌有明显的家族遗传倾向，通过基因检测可以预知乳腺癌的遗传风险。

2.乳腺良性疾病史

病理流行病学研究发现，乳腺癌危险性与某些乳腺良性病变(无害变异 breast lesions，BBL)有关，约30％BBL为增生性病变是乳腺癌的危险因素，以癌前增生者(重度非典型增生和部分囊性增生病)尤甚，报道有AH的女性患乳腺癌的危险性比无乳腺增生疾病的女性高4.2倍\\footnote{Dupont W D， Pad FF， Hartmann W H ， et a1．Breast cancer risk associated with proliferative breast disease and atypical hyperplasia[J]．Cancer，1993，71(4)：1258}。

3.年龄

年龄与乳腺癌发生有密切关系，20岁以下发病极为罕见，30岁以下较少见，30岁以上发病率开始上升。据统计，乳腺癌发病率有两个高峰，一个在绝经前，发病率低的国家在40～49岁。谢炳銮等研究发现，40～49岁年龄段乳腺癌的发生率最高为52.3％；而美国、英国等高发国家在50～55 岁；另一个小高峰在绝经后65～70岁\\footnote{谢炳銮，胡一迪，吕世旭，等．温州地区287例乳腺癌普查分析报告[J]．中国高等医学教育，2011，6：108}。

4.月经

月经是乳腺癌重要的影响因素。国内外许多研究均已证实月经初潮年龄早(小于11岁)，绝经年龄晚(大于55岁)，行经年数长是乳腺癌的危险因素\\footnote{Santen RJ，Boyd NF，Chlebow ski RT et a1．Breast cancer prevention collaborative group．critical assessment of new risk factors for breast cancer：considerations for development of an improved risk prediction model[J]．Endocr Rela Cancer，2007，14 (2)：169}。

5.生育

大量流行病学调查发现，未生育妇女患乳腺癌危险性较生育妇女高，初产早且足月妊娠是乳腺癌保护因素。初产年龄大于30岁危险性增加，大于35岁比未生育妇女还高\\footnote{于春梅，纪凤颖，付登科．女性乳腺癌影响因素病例对照研究[J]．中国公共卫生，2009，25(7)：772}。因此适龄结婚、适龄生育是预防乳腺癌的重要措施。

6.哺乳

大量调查研究发现，乳腺癌高发区较低发区人群的母乳喂养普及率低，且维持时间短，说明产后哺乳、母乳喂养时间长可降低乳腺癌发病风险\\footnote{覃芳葵，吴朝学．女性乳腺癌与部分行为因素的病例对照研究分析[J]．预防医学情报杂志，2011，27(2)：84}。

7.心理

大量研究证实，经历过多应激性生活事件及其伴随的烦恼、焦虑、疲倦和抑郁情绪是乳腺癌发病的重要危险因素。国内病例对照研究证实，经历过严重生活事件的妇女，患乳腺癌的相对危险性可提高2 ～3倍。有重大精神创伤的人群患乳腺癌的风险较高，而良好的人际关系和精神状况有降低患乳腺癌的风险\\footnote{聂建云，金丛国，唐一吟，等．行为因素对云南省妇女乳腺癌患病的影响[J]．现代肿瘤医学，2009，17(4)：65}。

8.生活方式

饮食习惯多数研究证明，高脂肪、腌制食品、低蔬菜饮食与乳腺癌发生存在强关联性。临床研究发现，脂肪饮食可改变内分泌环境，加强或延长雌激素对乳腺上皮细胞的刺激而增加患乳腺癌风险\\footnote{于春梅，纪凤颖，付登科．女性乳腺癌影响因素病例对照研究[J]．中国公共卫生，2009，25(7)：772}。

9.饮酒

流行病学调查发现，饮酒与乳腺癌有一定相关性。乳腺癌危险性随着酒精消耗量的增加而上升，特别是每天消耗大于10 g 酒精，危险性增加7％，经常每日饮酒，估计到75岁每1000人将有11 人发生乳腺癌\\footnote{Allen NE，Beral V，Casabonne D et a1．Moderate alcohol intake and cancer incidence in women [J]．J Natl Cancer
Inst，2009，101(5)：296}。

10.体重

体重上升会增加患乳腺癌的风险：一项研究发现，≥60岁和60岁乳腺癌组BMI均显著性高于健康对照组\\footnote{王越．体质指数与乳腺癌的关系[J]．肿瘤学杂志，2011，17 (3)：177}。也有很多证据表明在乳腺癌诊断时肥胖意味着乳腺癌复发的风险和死亡的风险更高，预后更差。

综上所述，乳腺癌是由多种因素共同作用并产生联合效应所导致的结果，除上述危险因素外，尚有药物、其他系统疾病、职业、病毒、体育锻炼、电离辐射等众多危险因素。因此，针对可能存在的危险因素，提倡妇女适时婚育、产后哺乳、加强普及乳腺病自我检查知识，做好乳腺癌家族高危人群的监控，保持健康的心态及稳定、乐观的情绪，合理膳食。开展乳腺疾病普查从而达到早检查、早发现、早治疗，对乳腺癌的防治有重大意义。

\\subsection{乳腺癌的高危人群}

年龄增加、遗传基因、生活方式等方面的不同，使得某些女性患乳腺癌的几率较一般女性为高，她们的特征是：

1.本身即患有乳癌或卵巢癌、有乳癌家族史(第一代亲属(母亲、姐妹等)中，如果有乳腺癌发病，这个家族就属于高危人群

2.未生育或35岁以后才生育、40岁以上未曾哺乳或生育

3.初经在12岁以前、停经过晚（如：55岁以后才停经者）

4.家族中有男性乳腺癌患者

5.过于肥胖

6.经常摄取高脂肪或高动物性脂肪、爱吃熟牛肉

7.曾在乳部和盆腔做过手术

8.过度暴露于放射线或致癌源（例如：经常施行X光透视或放射线治疗）

9.经由其他癌症转移至乳房（例如：患子宫内膜腺癌者）

10.有慢性精神压迫

11.不常运动

\\subsection{如何预防乳腺癌}
乳腺癌的预防包括筛查、化学预防、相关生活方式调理、预防性手术等方式。

1.乳腺癌的筛查

目前全球常用的乳腺癌筛查手段包括乳腺自检、临床乳腺检查(clinical breast examination，CBE)、乳房X线摄影术(mammography，MAM)又名钼靶X线摄影、超声成像(ultrasonography，US)和磁共振成像(magnetic resonance imaging，MRI)等。

1)乳房自检

乳腺自检是早期发现乳腺癌的一个重要措施，简便易行。月经正常的妇女在来潮后第9-11天是乳腺自检的最佳时期，因为此时雌激素对乳腺的影响最小，乳腺处于相对静止状态，容易发现病变。

乳腺自检的方法：a）面对镜子，双臂举过头顶，仔细观察两侧乳房的形态是否正常，乳房皮肤有无异常（如红肿、皮疹、皮肤褶皱、浅静脉怒张等），观察乳头是否在同一水平线上，是否有抬高、回缩、凹陷，乳头有无异常分泌物，乳晕颜色是否正常；b）两肘努力向后使胸部肌肉紧绷，观察两侧乳房是否等高、对称，乳头乳晕和皮肤是否异常，然后用左手检测右侧乳房，右手检测左侧乳房；c）在淋浴时，皮肤湿润更容易发现乳房问题。用指端掌面慢慢在乳房处旋转检测乳房的各个部位及腋窝是否有肿块；d）取平卧位，将右手四指并拢并用指端掌面在左侧乳房处垂直滑动检查乳房各部位是否有肿块或其它变化，用同样的方法是用左手检测右侧乳房e）挤压乳头，看是否有异常分泌物。

\\begin{figure}[t]
		\\centering
		\\includegraphics{/share/nas1/tengwj/Pipeline/AiRuKang/report/AiRuKang_fig2.pdf}
\\end{figure}
2)临床乳腺检查

临床乳腺检查（CBE）是有乳腺专科临床医生以双手触诊的方式全面检查乳房、腋窝及锁骨上下区有无结节、皮肤增厚、皮肤异常、乳头内陷和乳沟溢液等现象，如发现肿块，可粗略了解肿块大小、硬度、活动度以及与周围组织的关系，以便开展进一步的检查以确诊乳腺癌。CBE是临床上不可缺少的乳腺检查方法，是其它各种影像学检查的基础，在乳腺癌筛查中常与乳房X线摄影术或超声成像联合使用。

3)超声成像

超声成像（US）是临床上应用广泛的乳腺实时成像检查方法，对囊性和实性肿块具有较好的鉴别价值，还可显示腋窝及锁骨上淋巴结等周围组织情况，在发展中国家的乳腺癌筛查中具有举足轻重的地位。

4)钼靶X线摄影

乳房X线摄影术（MAM）或钼靶X线摄影是利用X射线的物理性质以及人体乳房组织不同的等密度值、将乳房的二维图像投影于X光胶片上进行观察的诊断方法。是目前诊断乳腺疾病尤其是早期发现乳腺癌的最重要且最有效的方法，也是许多欧美发达国家工人的乳腺癌筛查首选手段。

5)磁共振成像

磁共振成像（MRI）获得的图像非常清晰而精细，可对人体各个部位进行多角度、多平面成像，分辨力高，能够更加客观而具体地显示人体内的解剖组织及其相邻关系，对病灶进行更好的定位和定性，在早期肿瘤的诊断中具有很大的应用价值。

这些筛查手段各有其优缺点，其筛查效能和适用人群各不相同。现在综述不同国家的筛查建议如下：




\\begin{table}
%\\newcommand{\\tabincell}[2]{\\begin{tabular}{\@{}#1\@{}}#2\\end{tabular}}
%\\newcommand{\\tabincell}[2]{\\begin{tabular}{p{5cm}}{\@{}#1\@{}}#2\\end{tabular}}
\\newcommand{\\tabincell}[2]{\\begin{tabular}{p{5cm}\@{}#1\@{}}#2\\end{tabular}}
  \\centering
  {\\six\\begin{tabular}{p{3cm}p{5.1cm}p{5.5cm}}
  \\toprule[1.4pt]
\\textbf{组织（年份）} & \\textbf{针对一般人群的筛查建议} & \\textbf{针对高危人群的筛查建议}\\\\
 \\midrule
 \\rowcolor{linecolor1}
中国抗癌协会乳腺癌专业委员会(2015) & \\tabincell{l}{20～39岁\\\\
不推荐对非高危人群进行乳腺筛查。\\\\
40～49岁\\\\
(1)适合机会性筛查。(2)每年1次乳腺X线检查。(3)推荐与临床体检联合。(4)对致密型乳腺(腺体为c型或d型)推荐与B超检查联合。\\\\
50～69岁\\\\
(1)适合机会性筛查和人群普查。(2)每1～2年1次乳腺X线检查。(3)推荐与临床体检联合。(4)对致密型乳腺推荐与B超检查联合。\\\\
70岁或以上\\\\
(1)适合机会性筛查。(2)每2年1次乳腺X线检查。(3)推荐与临床体检联合。(4)对致密型乳腺推荐与B超检查联合。\\\\} & \\tabincell{l}{建议对乳腺癌高危人群提前进行筛查(25～40 岁)，筛查间期推荐每年1次，筛查手段除了应用一般人群常用的临床体检、彩超和乳腺X线检查之外，还可以应用MRI 等新的影像学手段。}\\\\
美国癌症学会（2007） & 20-39岁女性每3年接受1次CBE筛查，40岁以后每年先后各参加1次CBE和MAM 筛查；不推荐MRI筛查。 & 已知BRCA突变、未检出BRCA突变担忧BRCA突变直系亲属或乳腺癌终生风险在20\\%-25\\%以上的女性应参加MRI筛查。 \\\\
 \\rowcolor{linecolor2}
美国预防服务专家组（2009） & 40-49岁女性应根据家族史和健康状况等因素，咨询医生，综合考虑是否参加MAM筛查；50-74岁女性每2年参加一次MAM筛查。 & \\\\
加拿大预防保健工作组（2011） & 40-49岁女性无须参加MAM筛查；50-74岁女性每2-3年参加1次MAM 筛查，同时不再进行不必要的乳房自我检查和CBE。 & \\\\
\\rowcolor{linecolor2}
瑞典癌症研究所（2012） & 40岁以上女性每年参加1次CBE和MAM筛查。 & 腺癌终生患病风险在20\\%以上的女性每年参加1次MRI筛查。 \\\\
\\bottomrule


\\end{tabular}}
\\caption{\\six{CBE：临床乳腺检查；MAM：乳房X线摄影术（钼靶X线摄影）；US：超声成像；MRI：磁共振成像。}}
\\end{table}


2.乳腺癌化学预防

乳腺癌的化学预防是服用药物预防乳腺癌的发生或降低乳腺癌发生的风险。癌变是个复杂的、多步骤的漫长过程，涉及到基因与环境的相互影响，最终导致细胞的无限增殖。在癌变的演变过程中，首先是组织、细胞发生分化，即：癌前病变，然后经过长时间的发展成为浸润性肿瘤。这个过程为化学干预提供了时间上的可能性，使药物有足够的作用时间逆转细胞的异常分化。目前乳腺癌癌变的确切机制还不清楚，但一致认为乳腺的终末导管小叶单位（TDLUs，the terminal duct lobular units）是乳腺发生癌前病变的主要干细胞成分。导管增生（DH， ductal hyperplasia）、不典型增生（ADH， atypical ductal hyperplasia）、原位导管癌（DCIS， ductal carcinoma in situ）、原位小叶癌（LCIS， lobular carcinoma in situ）是癌前病变演变成恶性肿瘤这一连续过程中的组织学特征。在这一发展过程中，基因、分子发生了很多改变，及时识别这些改变并将其作为特异性的药物靶的则是乳腺癌化学预防的关键。主要的药物有：

1)他莫昔芬：具有抗雌激素的作用，1998年美国FDA认可高危人群服用他莫昔芬可以有效降低乳腺癌的风险。在临床上，观察到他莫昔芬可使转移或局部晚期的乳腺癌病变消退，还能减少对侧乳腺癌的发生率。英国通过近20年的随访研究发现，他莫昔芬可以降低39\\%的乳腺癌发病风险。虽然他莫昔芬有显著地降低乳腺癌发病风险的作用，但是对于ER阴性乳腺癌患者却没有明显作用 \\footnote{ogel VG1. Tamoxifen, raloxifene and tibolone decrease risk of invasive breast cancer in healthy women but increase risk of thromboembolism (tamoxifen, raloxifene), endometrial cancer (tamoxifen) or stroke (tibolone). Evid Based Med. 2010 Aug;15(4):122.}。

对于携带有{\\sl{BRCA1}}和{\\sl{BRCA2}}突变的乳腺癌患者，他莫昔芬也能降低对侧乳腺癌的发生风险。另外有研究证实他莫昔芬能减少62\\%携带{\\sl{BRCA2}}基因突变妇女的乳腺癌发病率。也有学者建议伴有小叶原位癌或非典型增生的高危妇女使用他莫昔芬，可能会获得比单纯伴乳腺癌家族史的妇女更好的益处。

他莫昔芬在服用过程中会增加静脉血栓的发生率、产生面部潮红、白带异常、增加子宫内膜癌的发生风险等副作用。这些副作用在绝经前妇女并不明显，而对绝经后妇女却又较明显影响。但是有研究显示他莫昔芬5年治疗结束后，血栓、面部潮红及妇科方面症状会消退。

2)雷洛昔芬：第二代选择性雌激素调节剂药物雷洛昔芬具有与他莫昔芬相似的预防作用（可减少45\\%-90\\%浸润性ER阳性肿瘤）且副作用小，不会增加子宫癌的发病风险。基于这些研究结果，FDA 批准了雷洛昔芬替代他莫昔芬用于高风险乳腺癌的预防。但是，雷洛昔芬治疗仍有潮热和增加相关血栓栓塞/心血管事件风险的副作用。此外，雷洛昔芬3年后的预防作用弱于他莫昔芬，在总体乳腺癌的预防疗效上仅为他莫昔芬的76\\%，在非浸润乳腺癌（导管原位癌[DCIS]）的预防疗效上是他莫昔芬的78\\%\\footnote{ Cauley JA, Norton L, Lippman ME, et al. Continued breast cancer risk reduction in postmenopausal women treated with raloxifene: 4-year results from the MORE trial. Multiple Outcomes of Raloxifene Evaluation. Breast Cancer Res Treat. 2001;65:125-134.} \\footnote{Grady D, Cauley JA, Geiger MJ, et al. Reduced incidence of invasive breast cancer with raloxifene among women at increased coronary risk. J Natl Cancer Inst. 2008;100:854-861.}。

3)拉索昔芬：属于第三代选择性雌激素受体拮抗剂。拉索昔芬是从骨质疏松症的治疗中开发出来的一种选择性雌激素调节剂药物，可用于低骨密度绝经后女性预防乳腺癌，拉索昔芬的绝经后评估和风险降低试验（PEARL）测试了拉索昔芬的疗效。这项Ⅲ 期临床预防试验的结果显示，拉索昔芬能够减少79％的浸润性乳腺癌和83％的ER阳性乳腺癌的发生\\footnote{LaCroix AZ, Powles T, Osborne CK, et al. Breast cancer incidence in the randomized PEARL trial of lasofoxifene in postmenopausal osteoporotic women. J Natl Cancer Inst. 2010;102:1706-1715.}。

4)芳香化酶抑制剂： 绝经后妇女的主要雌激素来源于外周组织（如脂肪组织、肌肉组织）中的雄性激素，雄性激素在芳香化酶的作用下转变为雌激素。芳香化酶抑制剂不像他莫昔芬或雷洛昔芬作用于雌激素受体，而是抑制芳香化酶，降低乳房组织的雌激素水平。对于绝经后妇女而言，芳香化酶抑制剂表现出优于雌激素受体拮抗剂的预后效果，并且可以降低对侧乳腺癌的风险。一项对芳香化酶抑制剂药物预防乳腺癌的研究中，绝经后乳腺癌高危女性接受了为期5年，每天给予依西美坦或安慰剂的干预，试验结果显示，依西美坦减少了65\\%的浸润性乳腺癌和73\\%的ER 阳性乳腺癌的发生\\footnote{Goss PE, Ingle JN, Ales-Martinez JE, et al. Exemestane for breast-cancer prevention in postmenopausal women. N Engl J Med. 2011;364:2381-2391.}。

5)HER2阳性乳腺癌

关于HER2癌基因的靶向药物能否有效地预防乳腺癌的研究，目前已有几项试验报道。最早的是2011 年Kuerer及其同事关于抗HER2 药物曲妥珠单抗用于HER2阳性DCIS患者的试验研究。在这项试验中，入组患者在手术前14至28天，被给予单剂量的曲妥珠单抗或安慰剂治疗。尽管切除的手术标本中HER2阳性DCIS的大小及生长速率无差异，但是在试验组中观察到了免疫反应。另一项曲妥珠单抗的III期试验紧随其后，该试验比较了2个单位曲妥珠单抗联合放疗、单药曲妥珠单抗及单用放疗在HER2阳性DCIS乳腺癌中的疗效，预计结果将在未来的几年内揭晓\\footnote{Kuerer HM, Buzdar AU, Mittendorf EA, et al. Biologic and immunologic effects of preoperative trastuzumab for ductal carcinoma in situ of the breast. Cancer. 2011;117:39-47.}。

6)ER阴性乳腺癌预防药物：他莫昔芬、雷洛昔芬、芳香化酶抑制剂等药物主要在雌激素受体阳性乳腺癌防治中显示出效果，对于雌激素受体阴性，乳腺癌预防则无明显改善。近来，发现rexinoids、 酪氨酸激酶抑制剂、环氧化酶-2抑制剂等也可能对雌激素受体阴性乳腺癌预防有所效用。

3.乳腺癌预防性手术

对携带BRCA突变基因的女性，乳房和卵巢切除术可能降低乳腺癌的发生风险。预防性乳腺切除可降低85\\%-95\\%乳腺癌发生风险。预防性双侧输卵管-乳腺切除术能降低乳腺癌的发病风险55\\%~70\\%。 是否采用预防性手术\\footnote{ Perabò M1, Fink V, Günthner-Biller M, von Bodungen V, Friese K, Dian D. Prophylactic mastectomy with immediate reconstruction combined with simultaneous laparoscopic salpingo-oophorectomy via a transmammary route: a novel surgical approach to female BRCA-mutation carriers. Arch Gynecol Obstet. 2014 Jun;289(6):1325-30.}，需要咨询临床医生的专业意见。

\\subsection{乳腺癌的预后}
评估乳腺癌的预后主要是从诊断后生存期和复发角度考虑。由于乳腺癌早期筛查技术的发展，乳腺癌的5年生存率已经从75\\%升高到了86\\%，也就是说86\\%的乳腺癌患者在诊断后可以生存5 年；10 年生存率为76\\%。无转移的乳腺癌患者（没有转移到淋巴系统或者其它系统）5年生存率可以高达96\\%，若有转移则5年生存率仅为21\\%。

因此乳腺癌的早发现早治疗有十分重要的意义。建议女性朋友了解一些乳腺疾病的科普知识，掌握乳腺自我检查方法，养成定期乳腺自查习惯，积极参加乳腺癌筛查，防患于未然。

\\clearpage


\\section{基因知识}
\\subsection{什么是基因}
基因（Gene）是遗传的基本物理和功能单位，由DAN构成，指导生物体内蛋白分子的合成。根成人体DNA的碱基从几百到两百万个不等。人类基因组计划估计人类基因组约有20000到25000个基因。人体内的成对基因一个来自父方、一个来自母方。人体内的大部分基因都是相同的，只有不到1\\%的一小部分基因有轻微差异。这些微小的差异造就了每个人独一无二的特点。

\\subsection{什么是染色体}
染色体是由螺旋状的DNA分子不断盘绕并与蛋白质串联在一起压缩形成的。细胞不发生分裂时，细胞核内的染色体即便是在显微镜下都是不可见的。但是，细胞发生分裂时，构成染色体的DNA 会变得更加紧密，这个时候就可以在显微镜下观察到染色体了。每个染色体都有一个叫“着丝粒”的收缩点，它可以将染色体分为两个部分或两个臂，其中短臂称为P臂，长臂称为q臂。每个染色体着丝粒的位置决定着染色体的特征形状，可以用来描述特定基因的位置。人体内共有24条不同的DNA分子，形成24条不同的染色体。染色体在细胞内成对出现，共23对，1-22号常染色体互相配对，性染色体X 和X 或Y配对，即每个细胞都含有46条染色体。2.5万个基因就分布在这23对不同染色体上，随着细胞的一分为二，所有遗传物质经复制后也随染色体分配到子代细胞，完成遗传物质的上下代传递。

\\subsection{基因是如何指导蛋白表达的}
大多数基因都含有合成蛋白的信息，除了有一小部分基因可以合成其他一些分子来帮助细胞合成蛋白。从基因到蛋白是一个复杂的过程，该过程在每个细胞中都有严格的控制。这个过程主要分为两步：转录和翻译。转录和翻译合起来称为基因的表达。

在基因的转录过程中，储存在DNA中的遗传信息被转移到一个叫做RNA的核糖核酸分子中。RNA和DNA 都是由一连串的核苷酸碱基对组成的，但是它们的化学特性稍有不同。含有蛋白合成信息的RNA 称为信使RNA（mRNA），因为其携带的信息或消息从原子核中的DNA进入了细胞质中。

第二步是从基因到蛋白的翻译过程，这一步在细胞质中进行，通过mRNA与细胞质内可以读取其碱基序列的的核糖体相互作用来完成。三个碱基对组成一个密码子来编码一个特定的氨基酸，这些氨基酸决定着蛋白质的基础。还有一类RNA称为转运RNA（tRNA），它可以一次转运一个氨基酸来对蛋白进行组装，但当遇到终止密码子时蛋白会停止组装。终止密码子是由三个碱基对组成的不编码蛋白的序列。

信息从DNA到RNA，再从RNA到蛋白质的流动是分子生物学的基本原则之一。因其非常重要，所以称为“中心法则”。

\\subsection{什么是基因突变}

基因突变是构成基因DNA序列的一种永久性的变化。变异的范围有大有小，包括从单个碱基对的改变到包含多个基因的染色体片段的改变。基因突变主要分为两类：遗传突变和获得性突变（体细胞突变）。

遗传突变来自父母，存在于整个身体细胞，贯穿于人的一生之中。这种突变又叫做生殖细胞突变，因为它们存在于父母的精子或卵子细胞当中。精子和卵子细胞也叫生殖细胞。精子和卵子细胞结合后产生的受精卵细胞继承了父母双方的DNA。 如果这个DNA发生突变，从受精卵生长发育成的孩子的每个细胞中都会携带有这种突变。

获得性突变或体细胞突变发生在生命中的某个阶段之中，而且只在特定的细胞中出现，并不会出现在人体的整个细胞当中。太阳紫外线照射等环境因素以及细胞分裂时DNA复制出错都会造成这种突变的发生。除了精子细胞和卵细胞外，发生在体细胞中的突变并不会传递给下一代。

\\subsection{基因突变如何影响健康与发展}
身体内每个细胞的正常运作都需要成千上万的蛋白在正确的时间正确的地点发挥正常作用。基因发生突变后无法指导蛋白正常合成，从而导致蛋白失灵或整个蛋白的缺失。当基因突变导致了对身体非常重要的蛋白发生改变后，人体正常的运作受到扰乱，严重者会导致疾病的发生。遗传物质（基因或染色体）发生突变后引起的疾病叫遗传病，通常在家族中垂直传递。

\\subsection{什么是基因检测}
基因检测是通过血液、其他体液或细胞对DNA进行检测的技术，是取被检测者脱落的口腔黏膜细胞或其他组织细胞，扩增其基因信息后，通过特定设备对被检测者细胞中的DNA分子信息作检测，预知身体患疾病的风险，分析它所含有的各种基因情况，从而使人们能了解自己的基因信息，从而通过改善自己的生活环境和生活习惯，避免或延缓疾病的发生。基因检测可以诊断疾病，也可以用于疾病风险的预测。疾病诊断是用基因检测技术检测引起遗传性疾病的突变基因。预测性基因检测即利用基因检测技术在疾病发生前就发现疾病发生的风险，提早预防或采取有效的干预措施。

\\subsection{怎样理解检测结果}
检测结果显示有风险意味着同正常人群相比，受检者本人患某种疾病的风险较高，但并不意味着受检者本人将来一定会患有该种疾病。众所周知，疾病是由遗传和环境共同作用的结果。若检测结果显示受检者患某些疾病的风险值比正常人群高，受检者可以通过避免疾病相关的诱因、健康规律的生活方式以及相应的医疗咨询和预防措施来降低疾病发生的风险，从而避免疾病的发生。具体措施需咨询相关医生。

此外，若检测结果显示有风险，建议受检者的直系亲属也参加检测，以便做好疾病的预防，降低疾病发生风险。
\\clearpage

\\section{乳腺癌与遗传}
\\subsection{遗传性乳腺癌综合征}
与遗传性乳腺癌相关的综合征有以下几类\\footnote{黄崇植，张国君. 家族性乳腺癌研究现状. 中国实用外科杂志,2011,10(31):972-974}：

1.Li-Fraumeni综合症

Li-Fraumeni综合症（LFS）是常染色体显性癌症易染综合症，与青少年时一系列肿瘤的发生相关。LFS患者易发生多发原发肿瘤包括骨肉瘤，软组织肉瘤，乳腺肿瘤，脑肿瘤，肾上腺皮质肿瘤，急性白血病，胰腺肿瘤，胃肿瘤，黑色素瘤，Wilms’瘤及其他肿瘤。P53突变携带者发生癌症的估计风险为85-90\\%。LFS为常染色体显性遗传癌症易感综合症，患者的每一个孩子都有50\\% 机会感染LFS，遗传疾病相关致病基因突变。

2.家族性腺瘤性息肉病（FAP）

FAP临床表现多样。除典型FAP外，目前已经发现3种FAP类综合症：轻表型家族性腺瘤性息肉病（AFAP），Gardner 综合症和Turcot综合症。AFAP表现为少于100个（平均30）腺瘤样息肉，主要见于近端结肠，但发展为大肠癌的几率很高。AFAP 患者诊断为结肠癌的平局年龄为50-55岁。
Gardner 综合症是FAP的一种变异形式，除有结肠腺瘤样息肉外，还具有肠外的表现如下颌骨和长骨骨瘤，软组织肿瘤（上皮样囊肿、纤维瘤及硬纤维瘤等）。Turcot综合症系指结肠多发息肉联合中枢神经系统肿瘤。诊断为FAP的75\\%患者来自于遗传，25\\%患者为新的突变所致。尽管家族内或家族间有着本病表型的一些变异，几乎所有携带突变APC 的患者都会发展为FAP。美国临床肿瘤协会（ASCO）等推荐基因检测作为对于FAP家族高危成员标准处理的手段之一。

3.遗传性非息肉病性结直肠癌（HNPCC)

遗传性非息肉病性结直肠癌（Hereditary Non-Polyposis Colorectal Cancer，HNPCC)， 又称为Lynch综合症， 指家族中发生结直肠癌或其他相关肿瘤如子宫内膜癌、胃癌、卵巢癌、小肠肿瘤、肝胆系上皮肿瘤、皮肤及脑部肿瘤等风险增大。HNPCC占所有结直肠癌中的3-5\\%。HNPCC患者在有生之年患结直肠癌的风险大约为80\\%。三分之二的患者肿瘤位于近端结肠。HNPCC结直肠癌患者典型发病年龄（44岁）要小于普通人群。因此这些患者不太可能在结肠癌的常规筛查中被发现。

4.Von Hippel-Lindau (VHL)综合症

VHL综合症是常染色体显性遗传性肿瘤。它以脑，脊髓和视网膜的血管母细胞瘤、肾囊肿和透明细胞癌、嗜铬细胞瘤、内淋巴囊肿瘤及附睾或阔韧带的乳头状囊腺瘤等为特征。家系内和家系间患者的临床表现及疾病严重程度可能大不相同。80\\%确诊为VHL 的患者遗传自家族成员，20\\%为新突变所导致。基因检测是对于有风险的VHL家族成员使用标准手段之一。除了可明确临床诊断的患者外，基因检测有助于在VHL极高风险患者显示出典型的临床表现之前进行早期确诊和干预。如果无症状的患者突变被证实，建议高度重视并进行常规和连续的门诊随访。

5.遗传性弥漫性胃癌

可分为遗传性弥漫型胃癌和家族性肠型胃癌。为常染色体显性遗传。其特点包括：基因外显率高（70\\%～80\\%），发病年龄早（平均38岁），病理类型一致，均为弥漫性胃癌（皮革胃）。该病没有早期诊断方法，胃镜检查及盲目胃活检不能早期发现病变。对于有明确突变的家庭成员而言，年轻时死于胃癌的风险很大，预防性全胃切除术是一种合理的选择。

6.家族性胰腺癌综合症(familial pancreatic cancer，FPC)

家族性胰腺癌是已经被确定的遗传肿瘤综合症，占全部胰腺癌的3\\%左右。对FPC的检查有利于发现胰腺癌的高危人群，包括家族中出现胰腺癌的其他成员和其他遗传肿瘤综合症：如皮肤黏膜黑色素斑- 胃肠道多发性息肉综合症(Peutz-Jeghers 综合症)、家族性非典型恶性黑色素瘤、家族性乳腺卵巢癌综合症、遗传性非腺瘤性结直肠癌等。对该综合症的确诊有助于更加准确地预测胰腺癌发病的危险，加强对高危人群的随访和及时的根治性手术是改善预后的重要方法。

7.遗传性乳腺癌-卵巢癌综合症（HBOC）

Lynch等于1972年首次描述了乳腺癌-卵巢癌综合症，并于1992年定义了3种明确的遗传性卵巢癌综合症：①遗传性非息肉性结肠直肠癌综合症(即LynchⅡ型)。②遗传位点特异性卵巢癌综合症。③ 遗传性乳腺癌-卵巢癌综合症。后者为3种综合症中最为常见的一种。携带{\\sl{BRCA1}}突变基因的乳腺癌妇女自确诊时起5年内患乳腺癌的风险为25\\%，至70岁时为64\\%。遗传性乳腺癌-卵巢癌综合女性症者患乳腺癌和(或)卵巢癌的发生率将大大增加，男性患者极易罹患睾丸癌。

8.Cowden病（CD）

PTEN基因种系突变引起的常染色体显性遗传病，特征是引起多种错构瘤和肿瘤。小脑的胚胎发育不良性神经节细胞瘤（Lhermitte-Duclos病）是其主要的中枢神经系统表现。神经系统外表现包括皮肤疣、口腔粘膜的卵石样丘疹和纤维瘤、多发面部毛根鞘瘤、结肠错构瘤性息肉。

9.口周色素沉着一肠道息肉综合征

口周色素沉着一肠道息肉综合征又称Putz—Jegher综合征(PJS)，是一种少见的常染色体显性遗传性疾病。以口唇、手指、足趾等部位黑／褐色色素沉着和胃肠道多发息肉为主要特征。超过90％的PJS 患者会发生小肠肠道错构瘤息肉，并且息肉一般产生于胃部和结肠直肠。在PJS患者中，常容易发生肠道、胰腺、卵巢、睾丸、乳房和子宫的良、恶性肿瘤。

\\subsection{基因与乳腺癌风险}
遗传易感性相关的乳腺癌约占所有乳腺癌的10\\%，其中有明确遗传因子的称为遗传性乳腺癌。迄今已报道且有详尽研究的乳腺癌易感基因包括{\\sl{BRCA1}}、{\\sl{BRCA2}}、{\\sl{CHEK2}} 等，以下将阐述其乳腺癌的关系。

1.{\\sl{BRCA1}} 与{\\sl{BRCA2}}

{\\sl{BRCA1}}和{\\sl{BRCA2}}基因是肿瘤抑制基因，遗传模式是常染色体显性遗传。这两个高外显率的基因，发生突变后增加了乳腺癌、卵巢癌（包括原发性腹膜癌与输卵管癌）、胰腺癌及前列腺癌的风险。研究标明，携带有{\\sl{BRCA1}}基因突变的女性到70岁时患乳腺癌的累积风险为57-87\\%，患卵巢癌的累积风险39-40\\%。BRCA1突变男性携带者到70岁时患乳腺癌的累积风险为1.2\\%。而携带{\\sl{BRCA2}}基因突变的女性到70 岁时患乳腺癌的风险为45-84\\%，卵巢癌的风险为11-18\\%.男性{\\sl{BRCA2}}突变携带者到65 岁时患前列腺癌的累积风险为15\\%，到70岁时患乳腺癌的累积风险为6.8\\%\\footnote{Shannon KM Chittenden A. Genetic testing by cancer site: breast. Cancer J. 2012. 18(4):310-9}。{\\sl{BRCA1/2}}突变携带者患黑色素瘤、胰腺癌及其他癌症的风险也会上升\\footnote{van Asperen CJ, et al. Cancer risks in {\\sl{BRCA2}} families: estimates for sites other than breast and ovary. J Med Genet. 2005. 42(9):711-9.}。

2.{\\sl{ATM}}

{\\sl{ATM}}是一种与常染色体显性遗传病共济失调-毛细血管扩张症（AT）相关的基因。其临床特征为发病年龄在1-4岁的进行性小脑共济失调、结膜毛细血管扩张、眼球运动失用、免疫缺陷及白血病和淋巴瘤等恶性肿瘤易感性倾向。携带{\\sl{ATM}}突变的女性患乳腺癌的风险增加2-4倍\\footnote{Renwick A, et al. ATM mutations that cause ataxia-telangiectasia are breast cancer susceptibility alleles. Nat Genet. 2006. 38(8):873-5.}。携带{\\sl{ATM}}突变的男性其患癌风险目前无法得知。目前有研究报道家族性腺癌患者的生殖细胞中有{\\sl{ATM}}突变。其中一项研究发现，在4.6\\%的家族中，有三个以上成员携带有{\\sl{ATM}}突变\\footnote{Roberts NJ, et al. {\\sl{ATM}} Mutations in patients with hereditary pancreatic cancer. Cancer Discovery. 2011. 2(1):OF1-OF6}。

3.{\\sl{BARD1}}，{\\sl{BRIP1}}，{\\sl{MRE11A}}，{\\sl{NBN}}，{\\sl{RAD50}}，{\\sl{RAD51C}}和{\\sl{RAD51D}}

范可尼贫血（Fanconi anemia，FA）是一种罕见的常染色体隐性遗传性血液系统疾病，因其DNA损伤修复能力的缺乏而造成各种癌症的发生。非FA人群的乳腺癌、卵巢癌及胰腺癌等肿瘤中均存在FA-BRCA 通路的损伤缺失。{\\sl{BARD1}}， {\\sl{BRIP1}}， {\\sl{MRE11A}}， {\\sl{NBN}}， {\\sl{RAD50}}， {\\sl{RAD51C}}，和{\\sl{RAD51D}}是参与FA-BRCA通路的一些关键基因，可与{\\sl{BRCA1}} 及{\\sl{BRCA2}}基因相互作用，在损伤DNA的同源重组修复中起着重要作用。这些基因发生突变后会导致乳腺癌的发病风险增加三倍。迄今为止，每个基因突变被报道至少导致一例卵巢癌的发生。与卵巢癌发病风险相关的基因{\\sl{RAD51C}}和AD51D突变估计分别占9\\%和10\\%{\\sl{BRIP1}}，{\\sl{NBN}}和AD51C基因各自与影响多个身体系统的常染色体隐性遗传病相关。

4.{\\sl{CHEK2}}

{\\sl{CHEK2}}是一个重要的乳腺癌易感基因，其编码的蛋白是一种在DNA双链断裂后做出反应的信号转导蛋白。{\\sl{CHEK2}}基因与{\\sl{BRCA1}}，{\\sl{BRCA2}}及{\\sl{TP53}}基因相互作用后参与维持染色体稳定的整个细胞过程。多项研究表明，{\\sl{CHEK2}}基因突变可增加乳腺癌、结肠癌等癌症的发病风险。这些突变在双边和单边乳腺癌女性患者中更为常见。女性{\\sl{CHEK2}}基因突变携带者一生之中乳腺癌发病风险增加约2倍，约有1\\%的风险发展成为第二个原发性乳腺癌，患其他癌症的终生风险不得而知。此外，该突变导致的卵巢发病风险的增加已经得到越来越多的重视\\footnote{Walsh T, et al. Mutations in 12 genes for inherited ovarian, fallopian tube, and peritoneal carcinoma identified by massively parallel sequencing. Proc Natl Acad Sci U S A. 2011. 108(44):18032-7.}。

5.{\\sl{CDH1}}

上皮钙黏蛋白E-cadherin的编码基因{\\sl{CDH1}}是一种肿瘤抑制基因和肿瘤转移抑制基因，与多种上皮来源的恶性肿瘤的发生、发展、侵袭转移密切相关。{\\sl{CDH1}}种系突变与遗传性弥漫性胃癌及女性乳腺浸润性小叶癌相关。女性浸润性小叶癌风险的升高与遗传性弥漫性胃癌相关，其乳腺癌终生风险值为39-52\\%\\footnote{ Guilford P et al. Hereditary diffuse gastric cancer: translation of {\\sl{CDH1}} germline mutations into clinical practice. Gastric Cancer. 2010. 13(1):1-10.}。

6.{\\sl{MUTYH}}

{\\sl{MUTYH}}基因种系突变会导致与{\\sl{MUTYH}}相关的息肉病，该病是一种常染色体隐性遗传病，容易诱发胃肠道息肉及结直肠癌。{\\sl{MUTYH}}基因突变携带者患结直肠癌的终生风险评估为80\\%。 此外，有研究表明，{\\sl{MUTYH}}基因突变会增加女性乳腺癌发生的风险，在北非犹太人群中评估乳腺癌的终生发病风险值为1.5倍\\footnote{American Congress of Obstetricians and Gynecologists Committee on Genetics. Committee Opinion No. 634: Hereditary cancer syndromes and risk assessment. Obstet Gynecol.}。携带{\\sl{MUTYH}}基因突变也会增加十二指肠、胃部及子宫内膜等部位癌症的终生发病风险。{\\sl{MUTYH}}基因突变对于男性乳腺癌发病的风险评估目前尚不清楚。

7.{\\sl{NF1}}

 {\\sl{NF1}}基因突变会导致I型神经纤维瘤病的发生，该病是一种常染色体显性遗传病，其临床特征有发性咖啡斑、腋窝和腹股沟斑点、多发性皮肤纤维瘤及虹膜斑块等。与{\\sl{NF1}}突变相关的常见肿瘤有外周神经鞘瘤，胃肠道间质瘤、枢神经系统胶质瘤、白血病、神经节细胞瘤、嗜铬细胞瘤及乳腺癌等。多项研究表明携带{\\sl{NF1}}突变的女性乳腺癌的终生患病风险增加3-5倍\\footnote{Seminog OO，et al. Age-specific risk of breast cancer in women with neurofibromatosis type 1. Br J Cancer. 2015 Apr 28;112(9):1546-8}。

8.{\\sl{PALB2}}

{\\sl{PALB2}}基因种系突变可增加胰腺癌、乳腺癌、N型范可尼贫血症的终生发病风险。由{\\sl{PALB2}}基因突变导致的家族性胰腺癌及乳腺癌是一种常染色体显性遗传方式，但N型范可尼贫血症是一种影响多个身体系统的罕见的常染色体隐性遗传病。携带{\\sl{PALB2}}基因变的女性乳腺癌的患病风险增加2-4倍。2014年的一篇研究表明，在乳腺癌的家族史中，{\\sl{PALB2}}基因突变导致的乳腺癌发生风险可达58\\%。不考虑乳腺癌的家族史，乳腺癌的发病风险为33\\%。最近的研究在1-3\\%的胰腺癌家族中发现了{\\sl{PALB2}}基因突变，但是并没有确定胰腺癌的准确终生风险。此外，{\\sl{PALB2}} 基因导致的卵巢癌风险的增加也得到了重视\\footnote{Evans MK, Longo DL.{\\sl{PALB2}} mutations and breast-cancer risk. N Engl J Med. 2014 Aug 7;371(6):566-8.}。

9.{\\sl{PTEN}}

{\\sl{PTEN}}是一种与Cowden综合征、{\\sl{PTEN}}错构瘤综合征、Bannayan -Riley-Ruvalcaba 综合征及泛自闭障碍相关的基因。Cowden综合征是一种多发性错构瘤综合征，其发展成为甲状腺癌、乳腺癌及子宫内膜癌的风险极高，同时伴随有皮肤黏膜损伤，甲状腺异常，纤维囊性病，多发性子宫肌瘤及畸形巨头等。Cowden综合征患者乳腺癌发生的终生风险可达50\\%\\footnote{Seo M, Cho N, Ahn HS, Moon HG. Cowden syndrome presenting as breast cancer: imaging and clinical features. Korean J Radiol. 2014 Sep-Oct;15(5):586-90.}，甲状腺癌的终生风险可达10\\%，子宫内膜癌的终生风险为5-10\\%。超过90\\%的Cowden综合征患者在二十多岁的时候会有临床症状发生。最近研究发现{\\sl{PTEN}} 基因突变会增加肾细胞癌、结直肠癌及其他癌症的发病风险。一项研究发现{\\sl{PTEN}}基因突变携带者肾癌发病风险同健康人群相比增加了31倍。

10.{\\sl{TP53}}

{\\sl{TP53}}是一种肿瘤抑制基因，其种细胞突变与Li-Fraumeni综合征相关。{\\sl{TP53}}基因突变携带者在30岁时癌症的发病风险为21-49\\%，期终生癌症发病风险可达68-93\\%。Li-Fraumeni综合征家族最常见的肿瘤类型包括软组织骨肉瘤、乳腺癌、脑肿瘤（包括星型细胞瘤、成胶质细胞瘤、成神经管细胞瘤和脉络丛癌）及肾上腺皮质癌。此外，也有报道发现结直肠癌、胃癌、卵巢癌、胰腺癌及肾癌等。研究发现有一小部分未携带{\\sl{BRCA1}}和{\\sl{BRCA2}}基因突变的早发性乳腺癌女性患者其{\\sl{TP53}}基因发生了突变\\footnote{Walsh T, et al. Spectrum of mutations in {\\sl{BRCA1}}, {\\sl{BRCA2}}, {\\sl{CHEK2}}, and {\\sl{TP53}} in families at high risk of breast cancer. JAMA. 2006. 295(12):1379-88.}。

\\clearpage

\\section{附录：所有变异汇总}
{\\six\\begin{longtable}{p{0.7cm}p{1cm}p{1.5cm}p{0.7cm}p{0.7cm}p{1cm}p{1cm}p{1cm}p{1.3cm}p{1.3cm}}
\\arrayrulecolor{tabcolor}
\\toprule
%\\rowcolor{linecolor1}
{\\textbf{Num}} & {\\textbf{Chrom}} & {\\textbf{Position start}} & {\\textbf{Ref}} & {\\textbf{Var}} & {\\textbf{Allele}} & {\\textbf{Region}} & {\\textbf{Gene}} & {\\textbf{Mutation type}} & {\\textbf{dbSNP}} \\\\
\\midrule
\\endhead
$table_all_end
\\bottomrule
\\end{longtable}}
{\\six{Num：编号；Chrom ：染色体号；Position start ：变异起始位置；Ref：参考基因组碱基；Var:变异碱基；Region：变异碱基在基因组上的位置exonic:外显子上，intronic：内含子上，UTR3：3’端非翻译区UTR5：5’：非翻译区，upstream：上游区域；Gene：变异所处的基因；Mutation type：变异类型，sSNV：同义突变，nSNV：非同义突变； dbSNP：定位的SNP 号。}}
 \\clearpage

\\section{报告说明}
爱汝康检测针对乳腺癌所涉及的18个基因，依据当今科研成果并结合先进的基因测序技术科学准确地提供测序结果和评估乳腺癌遗传风险。爱汝康检测报告报出的是与{\\sl{BRCA1}}、{\\sl{BRCA2}} 等18个基因相关的乳腺癌的遗传风险，并不用于其他特殊风险因素的决定性分析，报告结果不能替代临床诊断，请您结合本结果与您的临床医生或者合格的医疗保健专业人士一起，以本报告为基础，结合您的家族史和其他风险因素来评估您个人当下的乳腺癌患病风险。

爱汝康保证测序结果都是准确的，每一份报告都是真实的。

爱汝康保证每一位客户的信息都不会外泄，并且尊重您的意见合理合法保存处理您的DNA样本和检测报告。

爱汝康提供的结果仅对送检样本负责，对样本来源不承担任何意义的审查义务以及法律责任。

对于非实验和操作造成的样本异常，而导致的结果不准确，爱汝康不承担责任。

本结果为科研数据，不做他用。若因受检者或者送检单位不当使用该结果带来的风险以及损失，概由送检单位以及受检者承担。

爱汝康的检测结果的解释权归北京百迈客生物科技有限公司。

\\clearpage


\\ThisTileWallPaper{\\paperwidth}{\\paperheight}{/share/nas1/tengwj/Pipeline/AiRuKang/report/end.pdf}
\\null
\\clearpage


\\end{document}




";
close FOUT2;


sub aachn {
    my ($name) = @_;
    $aa{Ala} = "丙氨酸";
    $aa{Val} = "缬氨酸";
    $aa{Leu} = "亮氨酸";
    $aa{Ile} = "异亮氨酸";
    $aa{Pro} = "脯氨酸";
    $aa{Phe} = "苯丙氨酸";
    $aa{Trp} = "色氨酸";
    $aa{Met} = "甲硫氨酸";
    $aa{Gly} = "甘氨酸";
    $aa{Ser} = "丝氨酸";
    $aa{Thr} = "苏氨酸";
    $aa{Cys} = "半胱氨酸";
    $aa{Tyr} = "酪氨酸";
    $aa{Asn} = "天冬酰胺";
    $aa{Gln} = "谷氨酰胺";
    $aa{Lys} = "赖氨酸";
    $aa{Arg} = "精氨酸";
    $aa{His} = "组氨酸";
    $aa{Asp} = "天冬氨酸";
    $aa{Glu} = "谷氨酸";
    return $aa{$name};
}



sub USAGE {

	my $usage=<<"USAGE";
------------------------------------------------------------------------------------------------
		
		-Result_file
		-Parameter_file
		-Output_directory
		-help
------------------------------------------------------------------------------------------------
USAGE
	print $usage;
	exit;
}
