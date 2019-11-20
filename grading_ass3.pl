#!/usr/bin/perl

use strict ;
use warnings ;
use POSIX qw(floor ceil log); 

my $first = shift;
my $VECT = $ENV{'EE271_VECT'};
my $curDir = $ENV{'PWD'};

print "Currently grading the tarball: $first\n" ;

my $filesize = `du $first` ;
my @filesizes = split /\s+/ , $filesize ;

if( $filesizes[0] > 200 ){
    print "TARBALL TOO LARGE !!!\n" ;
    print "Please clean all directories and remove unneccasary files \n";
    die "\n" ; #Remove for full grading
}

`ls | grep ee271_tmp` and `rm -fr ee271_tmp` ;
`mkdir -p ee271_tmp` ;
chdir 'ee271_tmp' ;
`tar -xzvf ../$first`  ;
`ls | grep assignment3` or die "Tarball didn't contain: assignment3\n";
chdir 'assignment3' ;

`ls | grep names.txt` or die "Couldn't find names.txt ....\n" ; 
my $blutBad = `cat names.txt`;
my @blutBadden = split /\n/ , $blutBad ;
(scalar(@blutBadden)==6 || scalar(@blutBadden)==9) or die "Bad format: names.txt";

$blutBadden[0] or die "Missing SUID 1" ;
$blutBadden[1] or die "Missing Name 1" ;
$blutBadden[2] or die "Missing Email 1" ;

$blutBadden[3] or die "Missing SUID 2" ;
$blutBadden[4] or die "Missing Name 2" ;
$blutBadden[5] or die "Missing Email 2" ;




`ls | grep Makefile` or die "No Makefile?\n";
`ls | grep verif` or die "No Verif Directory?\n";
`ls | grep rtl` or die "No RTL Directory?\n";
`ls | grep gold` or die "No Golden Directory?\n";
`ls | grep synth` or die "No Synth Directory?\n";

# verif checker
print "\nRunning Verif\n" ;
my $testvector = "$VECT/vec_271_01_sv_short.dat";
my $reference = $testvector;
$reference =~ s/.dat/_ref.ppm/;
my $verif_cmd = "make run RUN=\"+testname=$testvector\"  &> out.log";

print "$verif_cmd\n";
print "Running...\n";
`$verif_cmd`;

`ls sv_out.ppm` or die "Cannot find sv_out.ppm in your verif directory\n";

my $verifStatus = 0 ;
my $Perf = 0;

unless( `diff sv_out.ppm $reference` ){
    $verifStatus = 1 ;
}
`ls | grep sv_out.ppm` or $verifStatus = 0 ;

if( my $line = `cat run_bb.log | grep -i "JJ: cycle / triangle"` ){
    $line =~ /JJ: cycle \/ triangle\s+:\s+(\d+\.\d+)/;
$Perf = $1;
}

print "Finished. No fatal error so far...\n";

# synth checker 3
use Cwd qw();
my $path = Cwd::cwd();
print "$path\n";
# $ENV{LD_LIBRARY_PATH}=$path;

print "\n\nRunning Synthesis \n" ;
my $syn_cmd = "make cleanall run_dc  &> out.log";

print "$syn_cmd\n" ;
my $synthPass = 1 ;
my $synthTimingMet = 0 ;
my $synthClock = 0;
my $synthTmax = 1;
my $synthTarr = 1;
my $synthTsetup = 0;
my $synthTreq = 0;
my $synthArea = 0;
my $synthDynPower = 0;
my $synthLeakPower = 0;
my $synthPower = 0;

print "Running...\n";
`$syn_cmd` ; 
chdir 'synth';
`ls | grep dc.log` or die "Error: No synth log (synth/dc.log)\n";
if( `cat dc.log | grep Error | grep :` ){
    print "Error in Synthesis, check logs\n";
    print `grep -A 10 -B 10 -C 1 Error dc.log` ;
    print "Error in Synthesis, check logs\n";
    $synthPass = 0 ;
}
`ls reports | grep timing_report_maxsm` or die "Error: No Timing report
(synth/reports/timing_report_maxsm)\n";
if( `cat reports/timing_report_maxsm | grep -i slack | grep -i met` ){
    $synthTimingMet = 1 ;
}elsif( `cat reports/timing_report_maxsm | grep -i slack | grep -i viol` ){
    print "Timing Violated\n";
    $synthTimingMet = 0 ;
}
if( my $line = `cat reports/timing_report_maxsm | grep -i "library setup time"` ){
  $line =~ /library setup time\s+-(\d+\.\d+)\s+(\d+\.\d+)/ ;
  $synthTsetup = $1;
  $synthTreq = $2;
}
if( my $line = `cat reports/timing_report_maxsm | grep -i "data arrival time"` ){
  $line =~ /data arrival time\s+-(\d+\.\d+)/ ;
  $synthTarr = $1;
}
if( my $line = `cat reports/area_report | grep -i "Total cell area"` ){
  $line =~ /Total cell area:\s+(\d+\.\d+)/;
    $synthArea = $1;
}
if( my $line = `cat reports/power_report | grep -i "Total Dynamic Power"` ){
  $line =~ /Total Dynamic Power\s+=\s+(\d+\.\d+)\s+mW/ ;
    $synthDynPower = $1;
}
if( my $line = `cat reports/power_report | grep -i "Cell Leakage Power"` ){
  $line =~ /Cell Leakage Power\s+=\s+(\d+\.\d+)\s+mW/ ;
    $synthLeakPower = $1;
}
chdir "..";

my $throughput = 0;
my $nInstances = 0;
my $totalPower = 0;
my $totalArea = 0;

$synthTmax = $synthTsetup + $synthTarr;
$synthClock = $synthTsetup + $synthTreq;
if( $synthTimingMet ) {
$synthPower = $synthDynPower + $synthLeakPower;
$throughput = $Perf * $synthClock;
} else {
$synthPower = $synthDynPower*$synthClock/$synthTmax + $synthLeakPower;
$throughput = $Perf * $synthTmax;
}

$nInstances = ceil($throughput / 2.0);
$totalPower = $nInstances * $synthPower;
$totalArea = $nInstances * $synthArea;



print "Finished. No fatal error so far...\n";


chdir $curDir ;


# summarize
print( "Student 1: $blutBadden[1]\n" );
print( "Student 2: $blutBadden[4]\n" );
if (scalar(@blutBadden)==9) {
print( "Student 3: $blutBadden[6] $blutBadden[7]\n" );
print( "NOTE: You NEED to get permission from TAs if you work in a group
of three.\n");
}

$verifStatus==0 and print "\n\nFailed verif\n" ;
$verifStatus==1 and print "\n\nPassed verif\n " . 
    "\tPerformace: $Perf cycle/triangle\n" ;
$synthPass==0 and print "Failed synth\n" ;
$synthPass==1 and print "Passed synth\n " . 
 "\tThroughput: $throughput ns/triangle \tNumber of Instances: $nInstances\n".
 "\tTotal Power: $totalPower mW \t Total Area: $totalArea um^2\n";

print "\nYour complete results are in results.csv\n";


# for grading
open (MYFILE, '>results.csv');
my $string = "$nInstances, $totalPower, $totalArea," .
    "$verifStatus, $synthPass,$synthClock, $synthTmax, $Perf, $throughput, ". 
    "$synthPower, $synthArea, $synthDynPower, $synthLeakPower";


my $string_name = '$nInstances, $totalPower, $totalArea,' .
   '$verifStatus, $synthPass,$synthClock, $synthTmax, $Perf, $throughput, '. 
    '$synthPower, $synthArea, $synthDynPower, $synthLeakPower';


print MYFILE "SUID, Name, Email, $string_name\n";

if (scalar(@blutBadden)==9) {
print MYFILE "$blutBadden[0], $blutBadden[1] (3rd), $blutBadden[2], $string\n";
print MYFILE "$blutBadden[3], $blutBadden[4] (3rd), $blutBadden[5], $string\n";
print MYFILE "$blutBadden[6], $blutBadden[7] (3rd), $blutBadden[8], $string\n";
} else {
print MYFILE "$blutBadden[0], $blutBadden[1], $blutBadden[2], $string\n";
print MYFILE "$blutBadden[3], $blutBadden[4], $blutBadden[5], $string\n";
}
close MYFILE;
