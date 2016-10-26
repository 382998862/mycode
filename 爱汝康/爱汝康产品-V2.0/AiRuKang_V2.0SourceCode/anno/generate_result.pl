#usr/bin/perl -w
use strict;
use Getopt::Long;

my ($file_in,$file_out);
GetOptions (
        "help|?"=>\&USAGE,
        "i:s"=>\$file_in,
        "o:s"=>\$file_out,   
)or \&USAGE;
&USAGE unless ($file_in and $file_out);


#my $file_in = $ARGV[0];
#my $file_out = $ARGV[1];

open(FIN,$file_in)||die"$!";
open(FOUT,">$file_out");
print FOUT "Type\tDatabase\tPass\/Faild\tDepth\tFrequence\tAllele\tMutationType\tClinicSignificance\t Chrom\tPosition\tRef\tVariant\tregion.\tgene.\tChromosome\tStart\tEnd\tReference Allelel\tAlternative Allele\tallele.\tnum1.\tnum2\line\tsynonymous\texonic_variant_function\tid\tGene\tChrom\tPositionStart\tPositionEnd\tRegion\tRef\tVariant\tcDNAChange\tProtienChange\tMutationType\tClinicSignificance\tDatabase\tLinks\tCosmic\tRsNumber\tPMID\tVariationID\n";
while(<FIN>){
    chomp;
    my @line = split/\t/,$_;
    my ($het,$prop,$odd);
    if ($line[54] =~ /\%/) {   #20160810 +7 
        my ($freq) = $line[54] =~ /(\S+)\%/;  #decimal 20160802
        print "$freq\n";
        if ($freq > 10) {
            $prop = "����";
            $odd = 1;  #What??!
            if ($line[53] eq "0/1") {  #20160810 +7 
                $het = "�Ӻ�";
            }
            elsif ($line[53] eq "1/1") {  #20160810 +7 
                $het = "����";
            }
            else {
                $het = "-";
            }
        }
        else {
             $prop = "����";
            $het = "����";  #Caution!
            $odd = 0;  #��
        }
    }
    
    my $syn ;
			if ( $line[26] =~ /^nonsynonymous/ ) {
				$syn = "��ͬ��ͻ��";
			}
			elsif ($line[26] =~ /^synonymous/) {
				$syn = "ͬ��ͻ��";
			}
			else {
				$syn = "����ͻ��";
			}
    
    my $clin;
			if ($line[27] =~ /pathogenic/i ) {
			   $clin = "�к�ͻ��"; 
		          }
		          elsif ( $line[27] =~ /^Benign;_risk_factor$/) {
			   $clin = "δ֪ͻ��";  
		          }
		          elsif ($line[27] =~ /benign/i) {
			   $clin = "�޺�ͻ��"; 
		          }
			else{
			   $clin = "δ֪ͻ��"; 
		          }
    my $row3;
    if ( $line[37] > 20) {  #pass of failed
        $row3 = "Pass";
    }
    else{
         $row3 = "Failed";
    }
    if ($line[0] ne "-" && $line[16] eq "-") {
        if ($odd == 1 ) {
            print FOUT "$prop\t-\t$row3\t$line[37]\t$line[54]\t$het\t$syn\t$clin\t$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]\t$line[11]\t$line[12]\t$line[13]\t$line[14]\t$line[15]\t$line[16]\t$line[17]\t$line[18]\t$line[19]\t$line[20]\t$line[21]\t$line[22]\t$line[23]\t$line[24]\t$line[25]\t$line[26]\t$line[27]\t$line[28]\t$line[29]\t$line[30]\t$line[31]\t$line[32]\t$line[33]\n";
            #����(δ�����ݿ�)  �������Դ��� 
        }
        else {
            print FOUT "$prop\t-\t$row3\t$line[37]\t$line[54]\t$het\t-\t-\t$line[0]\t$line[1]\t$line[2]\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n";
            #����(δ�����ݿ�) �����Դ���
        }
    }
    elsif ($line[0] ne "-" && $line[16] ne "-") {
        if ($odd == 1 ) {
            print FOUT "$prop\t���ݿ�\t$row3\t$line[37]\t$line[54]\t$het\t$syn\t$clin\t$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]\t$line[11]\t$line[12]\t$line[13]\t$line[14]\t$line[15]\t$line[16]\t$line[17]\t$line[18]\t$line[19]\t$line[20]\t$line[21]\t$line[22]\t$line[23]\t$line[24]\t$line[25]\t$line[26]\t$line[27]\t$line[28]\t$line[29]\t$line[30]\t$line[31]\t$line[32]\t$line[33]\n";
            #����(�Ѽ��) �������Դ��� 
        }
        else {
            print FOUT "$prop\t���ݿ�\t$row3\t$line[37]\t$line[54]\t$het\t-\t-\t$line[0]\t$line[1]\t$line[2]\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n";
            #����(�Ѽ��) �������Դ��� 
        }
    }
    elsif ($line[0] eq "-" ) {
        my $ref = substr($line[22],0,1);
        if ($line[37] eq "-") {
            print FOUT "����\t���ݿ�\t$row3\t0\t0%\t$het\t-\t-\t$line[18]\t$line[19]\t$ref\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]\t$line[11]\t$line[12]\t$line[13]\t$line[14]\t$line[15]\t$line[16]\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n";
            #"����(δ���ǵ�)
        }
        elsif ($line[37] > 20) {
            print FOUT "����\t���ݿ�\t$row3\t$line[37]\t0%\t$het\t-\t-\t$line[18]\t$line[19]\t$ref\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]\t$line[11]\t$line[12]\t$line[13]\t$line[14]\t$line[15]\t$line[16]\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n";
            #print "����\t���ݿ�\tFailed\t$line[37]\t0%\t-\t$syn\t$clin\t$line[18]\t$line[19]\t$ref\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]\t$line[11]\t$line[12]\t$line[13]\t$line[14]\t$line[15]\t$line[16]\t$line[17]\t$line[18]\t$line[19]\t$line[20]\t$line[21]\t$line[22]\t$line[23]\t$line[24]\t$line[25]\t$line[26]\t$line[27]\t$line[28]\t$line[29]\t$line[30]\t$line[31]\t$line[32]\t$line[33]\n";
            #����(���Ƕȴ��
        }
        else {
            print FOUT "����\t���ݿ�\t$row3\t$line[37]\t0%\t$het\t-\t-\t$line[18]\t$line[19]\t$ref\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]\t$line[11]\t$line[12]\t$line[13]\t$line[14]\t$line[15]\t$line[16]\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n";
            #����(�ʿ�ʧ��) 
        }
    }
    
}


close FIN;
close FOUT;



sub USAGE
{
        my $usage=<<"Usage";
        Options:\n
        -i
        -o
        
Usage
        print $usage;
        exit;
       
}
