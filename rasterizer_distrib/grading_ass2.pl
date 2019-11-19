#!/usr/bin/perl

use strict ;
use warnings ;

my $first = shift;
my $VECT = $ENV{'EE271_VECT'};
my $curDir = $ENV{'PWD'};

print "Currently grading the tarball: $first\n" ;

my $filesize = `du $first` ;
my @filesizes = split /\s+/ , $filesize ;

if( $filesizes[0] > 20000 ){
    print "TARBALL TOO LARGE !!!\n" ;
    print "Please clean all directories and remove unneccasary files \n";
    die "\n" ; #Remove for full grading
}

`ls | grep ee271_tmp` and `rm -fr ee271_tmp` ;
`mkdir ee271_tmp` ;
chdir 'ee271_tmp' ;
`tar -xzvf ../$first`  ;
`ls | grep assignment2` or die "Tarball didn't contain: assignment2\n";
chdir 'assignment2' ;

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

# checker 1
print "\nRunning Verif\n" ;
my $testvector = "$VECT/vec_271_01_sv_short.dat";
my $reference = $testvector;
$reference =~ s/.dat/_ref.ppm/;
my $verif_cmd = "make clean run RUN=\"+testname=$testvector\" &> out.log";

print "$verif_cmd\n";
print "Running...\n";
`$verif_cmd`;

`ls verif_out.ppm` or die "Cannot find verif_out.ppm in your verif directory\n";

my $Status1 = 0 ;

unless( `diff verif_out.ppm $reference` ){
    $Status1 = 1 ;
}
`ls | grep verif_out.ppm` or $Status1 = 0 ;
print "Finished. No fatal error so far...\n";



# checker 2
# print "\n\nRunning Verif for Modified FSM Design\n" ;
# $testvector = "$VECT/vec_271_01_sv_short.dat";
# $reference = $testvector;
# $reference =~ s/.dat/_ref.ppm/;
# $verif_cmd = "make cleanall run RUN=\"+testname=$testvector\" GENESIS_PARAMS=\"top_rast.rast.test_iterator.ModifiedFSM=YES\" >& out.log";

# print "$verif_cmd\n";
# print "Running...\n";
# `$verif_cmd`;

# `ls verif_out.ppm` or die "Cannot find verif_out.ppm in your verif directory\n";

# my $Status2 = 0 ;

# unless( `diff verif_out.ppm $reference` ){
#     $Status2 = 1 ;
# }
# `ls | grep verif_out.ppm` or $Status2 = 0 ;

# print "Finished. No fatal error so far...\n";

# checker 3
use Cwd qw();
my $path = Cwd::cwd();
print "$path\n";
#`setenv LD_LIBRARY_PATH $path`;
#$ENV{LD_LIBRARY_PATH}=$path;

print "\n\nRunning Synthesis \@clk_period=1.2ns\n" ;
my $syn_cmd = "make cleanall run_dc CLK_PERIOD=1.2 &> out.log";

print "$syn_cmd\n" ;
print "Running...\n";
`$syn_cmd` ; 

my $synthStatus = 0 ;
chdir 'synth';
`ls reports | grep timing_report_maxsm` or die "No Timing report (synth/reports/timing_report_maxsm)\n";
if( `cat reports/timing_report_maxsm | grep -i slack | grep -i met` ){
    $synthStatus = 1 ;
}
if( `cat reports/timing_report_maxsm | grep -i slack | grep -i viol` ){
    print "Timing Violated\n";
    $synthStatus = 0 ;
}
`ls | grep dc.log` or die "No synth log (synth/dc.log)\n";
if( `cat dc.log | grep Error | grep :` ){
    print "Error in Synthesis, check logs\n";
    print `grep -A 10 -B 10 -C 1 Error dc.log` ;
    print "Error in Synthesis, check logs\n";
    $synthStatus = 0 ;
}
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

$Status1==0 and print "\n\nFailed verif\n" ;
$Status1==1 and print "\n\nPassed verif\n" ;
#$Status2==0 and print "Failed verif for Modified FSM Design\n" ;
#$Status2==1 and print "Passed verif for Modified FSM Design\n" ;
$synthStatus==0 and print "Failed synth \@clk_period=1.2ns\n" ;
$synthStatus==1 and print "Passed synth \@clk_period=1.2ns\n" ;


