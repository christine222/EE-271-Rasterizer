#!/usr/bin/perl


my $first = shift;
my $VECT = $ENV{'EE271_VECT'};

print "Currently grading the tarball: $first\n" ;

$filesize = `du $first` ;
@filesizes = split /\s+/ , $filesize ;

if( $filesizes[0] > 2000 ){
    print "TARBALL TOO LARGE !!!" ;
}

`ls | grep ee271_tmp` and `rm -fr ee271_tmp` ;
`mkdir ee271_tmp` ;
chdir 'ee271_tmp' ;
`tar -xzvf ../$first`  ;
`ls | grep assignment1` or die "looking for assignment1 in tarball... not found..." ;
chdir 'assignment1' ;

`ls | grep names.txt` or die "No names.txt in assignment1...." ;
$blutBad = `cat names.txt`;
@blutBadden = split /\n/ , $blutBad ;
(scalar(@blutBadden)==6 || scalar(@blutBadden)==9) or die "Bad format: names.txt";

print( "Student 1: $blutBadden[0] $blutBadden[1]\n" );
print( "Student 2: $blutBadden[3] $blutBadden[4]\n" );
if (scalar(@blutBadden)==9) {
print( "Student 3: $blutBadden[6] $blutBadden[7]\n" );
print( "NOTE: You NEED to get permission from TAs if you work in a group
of three.\n");
}

`ls | grep gold` or die "looking for directory gold in assignment1.... not found..." ;
`ls | grep Makefile` or die "looking for makefile in gold.... not found...";
`make cleanall comp_gold >& out.log` ;
`ls | grep rasterizer_gold` or die "looking for binary file rasterizer_gold... compiliation failed...";
`./rasterizer_gold out.ppm $VECT/vec_271_04_sv.dat` ;
`ls | grep out.ppm` or die "looking for output image file out.ppm... run failed...";

my $status = 0 ;

if( `diff out.ppm $VECT/vec_271_04_sv_ref.ppm` ){
    print("Failed\n");
    $status = 0 ;
} else {
    print("Passed\n");
    $status = 1 ;
}
if (scalar(@blutBadden)==9) {
print( "NOTE: You NEED to get permission from TAs if you work in a group
of three.\n");
}

chdir '../..' ;









