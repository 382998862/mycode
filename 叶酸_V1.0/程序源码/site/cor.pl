#!/usr/bin/perl
use strict;
use autodie;
use 5.01;

#writer:sunqh <sunqh\@biomarker.com.cn>
#data:2015
#用途

###############Time
my $Time_start;
$Time_start=sub_format_datetime(localtime(time()));
print "\nStart Time:[$Time_start]\n\n";
################

open I,'<','b' or die;
open O,'>>','c' or die;

my @lines = <I>;
@lines = sort{$b cmp $a} @lines;
#say @lines;

my $i = 0;
while($i < @lines){
        if($lines[$i]=~/^(\w+)\+/){
                chomp $lines[$i];
                chomp $lines[$i+1];
                my @l1 = split "\t",$lines[$i++];
                my @l2 = split "\t",$lines[$i];

                if($l1[3] eq $l2[3]){
                        say O $1."\t".$l1[1]."\t".$l1[2]."\t".$l2[3].$l1[3]."\tHom";
                }else{
                        say O $1."\t".$l1[1]."\t".$l1[2]."\t".$l2[3].$l1[3]."\tHet";
                }
        }
        $i++;
}

close I;
close O;



###############Time
my $Time_End;
$Time_End = sub_format_datetime(localtime(time()));
print "\nEnd Time :[$Time_End]\n\n";
##############


sub sub_format_datetime
{
        #Time calculation subroutine
    my($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = @_;
        $wday = $yday = $isdst = 0;
    sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}
# ------------------------------------------------------------------
# calculate the total run time
# ------------------------------------------------------------------
sub run_time {
	# get parameter
	my ($start_time) = @_;

	# calculate the run time
	my $run_time = time() - $start_time;

	# log
	log_current_time("Total elapsed time: ${run_time}s");
}

# ------------------------------------------------------------------
# print current time with some information
# ------------------------------------------------------------------
sub log_current_time {
	# get parameter
	my ($info) = @_;

	# get current time with string
	my $curr_time = format_datetime(localtime(time()));

	# print info with time
	print "[$curr_time] $info\n";
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
## qsub

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
