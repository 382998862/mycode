#!/usr/bin/perl
use strict; # CollapsedSubs: mkdir_or_die  log_and_exit  run_cmd_or_die  qsub  absolute_path
#use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw();
use File::Basename qw(basename dirname);

#�����ɵĻ����͵ı�����Ʒ���յĻ�����Ϣ�����кϲ���ȡ������Ϣ��

my %opts;
GetOptions(\%opts,"i1=s","i2=s");
my $I1  = $opts{i1} ;     #������Ϣ�ļ�
my $I2  = $opts{i2} ;     #���ɵĻ�����Ϣ�ļ�

if (!defined($opts{i1})||!defined($opts{i2}))
{
                print <<"Usage End.";

         Description:

             -i1                 Basic information file               From the production management system (download)

             -i2                 Gene information file                From the Looking sites program

Usage End.
        exit;
}

open(F1,"$I1") or die "open error:$!";
open(F2,"$I2") or die "open error:$!";

my @lines1=<F1> ;
my @lines2=<F2> ;

my $fileExist = -e "information";
unless( $fileExist )
{
        open(F3,">>information") or die "open error:$!";
        print F3 "number\tname\tsex\tage\treceivetime\treporttime\t1Fgene\t2Fgene\t5Fgene\n" ;
        close(F3);
}

###############Time
my $Local_time;
$Local_time=sub_format_datetime(localtime(time()));
print "\n$Local_time\n\n";
##############

open(F3,">>information") or die "open error:$!";
my $i = 1;
while($i < @lines1){
                chomp $lines1[$i];
                my @l1 = split "\t",$lines1[$i];
                my $number = $l1[1];
                $l1[1] =~ s/16000//g;
                #$l1[1] =~ s/F15000//g;
                my $j = 0;
                while($j < @lines2){
                chomp $lines2[$j];
                my @l2 = split "\t",$lines2[$j];
                if($l2[0] eq $l1[1])
                {
                print F3 $number."\t".$l1[5]."\t".$l1[6]."\t".$l1[7]."\t".$l1[3]."\t".$Local_time."\t".$l2[3]."\t".$l2[8]."\t".$l2[13]."\n";
                }
                $j++;
                }
        $i++;
}
close(F1);
close(F2);
close(F3);

print "T\n" ;

###############Time
#my $Time_End;
#$Time_End = sub_format_datetime(localtime(time()));
#print "\nEnd Time :[$Time_End]\n\n";
###############
sub sub_format_datetime
{
        #Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
        $wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d", $year+1900, $mon+1, $day);
}

# ------------------------------------------------------------------
# mkdir dir and check, if failed, then program will die
# ------------------------------------------------------------------
sub mkdir_or_die {
        # get parameter
        my ($dir) = @_;

        # check and mkdir
        `mkdir -p $dir` if(!-d $dir);

        # check mkdir result
        if(!-d $dir) {
                log_and_exit("Error: mkdir \"$dir\" is failed");
        }
}

# ------------------------------------------------------------------
# log_current_time() and exit(1)
# ------------------------------------------------------------------
sub log_and_exit {
        # log
        log_current_time(shift);
        # exit
        #exit(1);
        die;
}

# ------------------------------------------------------------------
# run cmd and check run status
# ------------------------------------------------------------------
sub run_cmd_or_die {
        # get parameter
        my ($cmd) = @_ ;

        # get cmd staring time
        my $start_time=time();

        # run cmd and check
        log_current_time("starting cmd: $cmd");
        my $flag = system($cmd) ;
        if ($flag != 0){
                log_and_exit("Error: command failed: $cmd");
        } else {
                log_current_time("end cmd: $cmd");
                run_time($start_time);
        }
}

# ------------------------------------------------------------------
# calling qsub
# ------------------------------------------------------------------
sub qsub {
        # get parameter
        my ($shfile, $maxproc, $queue) = @_ ;

        # check parameters
        if( ($queue ne "general.q") && ($queue ne "middle.q") && ($queue ne "great.q") ){
                log_and_exit("qsub queue error: quene($queue) not general.q, middle.q, or great.q");
        }

        # create cmd
        my $cmd = "";
        # at the cluster node
        if (`hostname` =~ /cluster/) {
                $cmd = "qsub-sge.pl --queue $queue --maxproc $maxproc --independent --reqsub $shfile" ;
        # at computing node
        } else {
                $cmd = "ssh cluster -Y qsub-sge.pl --queue $queue --maxproc $maxproc --independent --reqsub $shfile" ;
        }

        # run
        run_cmd_or_die($cmd);
}

# ------------------------------------------------------------------
# get absolute path for file or dir
# ------------------------------------------------------------------
sub absolute_path {
        # get parameter
        my ($in, $cur_dir) = @_;
        my $return = "";

        # get absolute path for file
        if(-f $in) {
                my $dir=dirname($in);
                my $file=basename($in);
                chdir $dir;
                $dir=`pwd`;
                chomp $dir;
                $return="$dir/$file";
        # get absolute path for dir
        } elsif(-d $in) {
                chdir $in;
                $return=`pwd`;
                chomp $return;
        # error
        } else {
                log_and_exit("Warning just for file and dir");
        }

        # reset current work dir
        chdir $cur_dir;
        # return
        return $return;
}
