: # feed this into perl *-*-perl-*-*
    eval 'exec perl -S $0 "$@"'
    if $running_under_some_shell;

use Cwd;
use Cwd 'abs_path';
use File::Find ();
use File::Basename;
use Math::Trig;
use Getopt::Std;

##-------------------------------Declare variables explicitly so "my" not needed.------------------------------------##
use strict 'vars';
use vars qw($opt_F $data $line @fields @index @z @zstagger @zDet @r @thetaDet @overlap @dx @dy @dz @tilt @roll @rollDet @rx @ry @rz @quartzCutAngle @refTopOpeningAngle @dzRef @dxLg @dyLg @dzLg  @lgTiltAngle @dxPmt @dyPmt @dzPmt @ddPmt @dtWall @dtReflector @numDet $i $j $k );
##-------------------------------------------------------------------------------------------------------------------##

##-------------------------------Get the option flags.------------------------------------------------------------------##
getopts('F:');


if ($#ARGV > -1){
    print STDERR "Unknown arguments specified: @ARGV\nExiting.\n";
    exit;
}
##----------------------------------------------------------------------------------------------------------------------##

##-----------------------Start reading CSV file containing parameter values.---------------------------------##
open($data, '<', $opt_F);                                         # Open csv file.

@numDet=(28,28,28,28,42,21,21,28);                                # Unelegant but needed placeholder for now.
$i=0;

while($line= <$data>){                                            # Read each line till the end of the file.
if ($line =~ /^\s*$/) {                                           # Check for empty lines.
    print "String contains 0 or more white-space character and nothing else.\n";
} else {
chomp $line;
@fields = split(",", $line);                                      # Split the line into fields. 
$index[$i]=trim($fields[0]);                                      # Get rid of initial and trailing white spaces.
$r[$i]=trim($fields[1]);                                          # Radial position of center of quartz.
$dz[$i]=trim($fields[2]);                                         # Length.
$overlap[$i]=trim($fields[3]);                                    # 0=minimum overlap, 1=maximum overlap.
$dx[$i]=trim($fields[4]);                                         # Thickness along beam direction.
if($index[$i]>=50 && $index[$i]<60){
$dy[$i]=  2*pi*($r[$i]-($dz[$i]*(0.5-$overlap[$i])))/(4*7*3)      # Calculating azimuthal width of detectors in moller ring.
}else{
$dy[$i]=  2*pi*($r[$i]-($dz[$i]*(0.5-$overlap[$i])))/(4*7)        # Calculating azimuthal width of detectors in all other rings. 
}
$tilt[$i]=trim($fields[5]);                                       # Tilt of quartz along beam direction.
$roll[$i]=trim($fields[6]);                                       # Roll about axis perpendicular to beam axis. 
$dzRef[$i]=trim($fields[7]);                                      # Length of reflector section.
$refTopOpeningAngle[$i]=trim($fields[8]);                         # Opening angle of reflector.
$lgTiltAngle[$i]=trim($fields[9]);                                # Tilt of light guide wrt to quartz. 
$dxLg[$i]=trim($fields[10]);                                      # Thickness of light guide
$dzLg[$i]=trim($fields[11]);                                      # Length of Light Guide
$ddPmt[$i]=trim($fields[12]);                                     # Diameter of PMT
$dzPmt[$i]= trim($fields[13]);                                    # Length of PMT
$dtWall[$i]= trim($fields[14]);                                   # Thickness of Wall 
$z[$i]=trim($fields[15]);                                         # Z-position  
$zstagger[$i]=trim($fields[16]);                                  # Staggered Z-position
$i=$i+1;

}
}

##----------------------------End reading CSV file containing parameter values.------------------------------------------##


##----------------------------Start writing parameter.csv for gdmlGenerator (Code works but lacks clarity. Need to check one to one correspondence between CAD and gdml azimuthal positioning.)----------------------------------------------##
open(def, ">", "parameter.csv") or die "cannot open > parameter.csv: $!";

for($j=0; $j<$i; $j++){
print "ring $index[$j]\n";

for($k=0;$k<$numDet[$j];$k++){

if($index[$j]==5.0){
$thetaDet[$k]=2*pi*(transt($k)+2)/84;
}elsif($index[$j]==5.1){
$thetaDet[$k]= 2*pi*(opent($k)+2)/84;
}elsif($index[$j]==5.2){
$thetaDet[$k]= 2*pi*(closedt($k)+2)/84;
}else{
$thetaDet[$k]= 2*pi*$k/28;
}

print "$thetaDet[$k]\n";

if($k%2==0){
$zDet[$k]=$z[$j];
}else{
$zDet[$k]=$zstagger[$j];
}

$rollDet[$k]=$roll[$j]+90;

print def "${index[$j]*1000+$k+1}, $zDet[$k], ${r[$j]*sin($thetaDet[$k])}, ${r[$j]*cos($thetaDet[$k])}, $dx[$j], $dy[$j], $dz[$j], $thetaDet[$k], ${tilt[$j]*pi/180}, ${rollDet[$k]*pi/180},  0.785398, ${refTopOpeningAngle[$j]*pi/180}, $dzRef[$j], $dxLg[$j], $dy[$j], $dzLg[$j], ${lgTiltAngle[$j]*pi/180}, ${ddPmt[$j]*25.4*1.005}, ${ddPmt[$j]*25.4*1.005}, ${dzPmt[$j]*25.4}, ${ddPmt[$j]*25.4/2}, $dtWall[$j], ${dtWall[$j]/5}  \n";



}
}



close(def) or warn "close failed: $!";
##-----------------------------------------------------------------------------------------------------------------------##




##--------------------------------------------Start writing equations.txt------------------------------------------------##

open(def, ">", "equations.txt") or die "cannot open > equations.txt: $!";
print def "\"D1\"=
\"D1\@Sketch1\@R1_quartz<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"q1W\"
\"q1L\"= $dz[0]mm
\"q2L\"= $dz[1]mm
\"q3L\"= $dz[2]mm
\"q4L\"= $dz[3]mm
\"q5transL\"= $dz[4]mm
\"q5openL\"= $dz[5]mm
\"q5closedL\"= $dz[6]mm
\"q6L\"= $dz[7]mm
\"q1r\"= $r[0]mm
\"q2r\"= $r[1]mm
\"q3r\"= $r[2]mm
\"q4r\"= $r[3]mm
\"q5transr\"= $r[4]mm
\"q5openr\"= $r[5]mm
\"q5closedr\"= $r[6]mm
\"q6r\"= $r[7]mm
\"q1W\"= $dy[0]mm
\"q2W\"= $dy[1]mm
\"q3W\"= $dy[2]mm
\"q4W\"= $dy[3]mm
\"q5transW\"= $dy[4]mm
\"q5openW\"= $dy[5]mm
\"q5closedW\"= $dy[6]mm
\"q6W\"= $dy[7]mm
\"q1tilt\"= $tilt[0]deg
\"q2tilt\"= $tilt[1]deg
\"q3tilt\"= $tilt[2]deg
\"q4tilt\"= $tilt[3]deg
\"q5transtilt\"= $tilt[4]deg
\"q5opentilt\"= $tilt[5]deg
\"q5closedtilt\"= $tilt[6]deg
\"q6tilt\"= $tilt[7]deg
\"D1\@Sketch1\@R2_quartz<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"q2W\"
\"D1\@Sketch1\@R3_quartz<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"q3W\"
\"D1\@Sketch1\@R5trans_quartz<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5transW\"
\"D1\@Sketch1\@R5open_quartz<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"q5openW\"
\"D1\@Sketch1\@R5closed_quartz<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5closedW\"
\"D1\@Sketch1\@R6_quartz<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"q6W\"
\"D2\@Sketch1\@R1_quartz<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"q1L\"
\"D2\@Sketch1\@R2_quartz<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"q2L\"
\"D2\@Sketch1\@R3_quartz<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"q3L\"
\"D2\@Sketch1\@R4_quartz<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"q4L\"
\"D2\@Sketch1\@R5trans_quartz<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5transL\"
\"D2\@Sketch1\@R5open_quartz<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"q5openL\"
\"D2\@Sketch1\@R5closed_quartz<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5closedL\"
\"D2\@Sketch1\@R6_quartz<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"q6L\"
\"D62\@skeleton\"=\"q1r\"
\"D50\@skeleton\"=\"q1r\"
\"D65\@skeleton\"=\"q2r\"
\"D63\@skeleton\"=\"q2r\"
\"D69\@skeleton\"=\"q3r\"
\"D67\@skeleton\"=\"q3r\"
\"D73\@skeleton\"=\"q4r\"
\"D71\@skeleton\"=\"q4r\"
\"D26\@skeleton\"=\"q5openr\"
\"D22\@skeleton\"=\"q5openr\"
\"D17\@skeleton\"=\"q5openr\"
\"D13\@skeleton\"=\"q5transr\"
\"D4\@skeleton\"=\"q5transr\"
\"D7\@skeleton\"=\"q5transr\"
\"D34\@skeleton\"=\"q5closedr\"
\"D41\@skeleton\"=\"q5closedr\"
\"D44\@skeleton\"=\"q5closedr\"
\"D77\@skeleton\"=\"q6r\"
\"D75\@skeleton\"=\"q6r\"
\"D79\@skeleton\"=\"q1tilt\"
\"D81\@skeleton\"=\"q1tilt\"
\"D83\@skeleton\"=\"q2tilt\"
\"D85\@skeleton\"=\"q2tilt\"
\"D87\@skeleton\"=\"q3tilt\"
\"D89\@skeleton\"=\"q3tilt\"
\"D93\@skeleton\"=\"q4tilt\"
\"D91\@skeleton\"=\"q4tilt\"
\"D46\@skeleton\"=\"q5closedtilt\"
\"D42\@skeleton\"=\"q5closedtilt\"
\"D36\@skeleton\"=\"q5closedtilt\"
\"D9\@skeleton\"=\"q5transtilt\"
\"D38\@skeleton\"=\"q5transtilt\"
\"D14\@skeleton\"=\"q5transtilt\"
\"D19\@skeleton\"=\"q5opentilt\"
\"D28\@skeleton\"=\"q5opentilt\"
\"D29\@skeleton\"=\"q5opentilt\"
\"D95\@skeleton\"=\"q6tilt\"
\"D97\@skeleton\"=\"q6tilt\"
\"refl1L\"= $dzRef[0]mm
\"refl2L\"= $dzRef[1]mm
\"refl3L\"= $dzRef[2]mm
\"refl4L\"= $dzRef[3]mm
\"refl5transL\"= $dzRef[4]mm
\"refl5openL\"= $dzRef[5]mm
\"refl5closedL\"= $dzRef[6]mm
\"refl6L\"= $dzRef[7]mm
\"refl1angle\"= $refTopOpeningAngle[0]deg
\"refl2angle\"= $refTopOpeningAngle[1]deg
\"refl3angle\"= $refTopOpeningAngle[2]deg
\"refl4angle\"= $refTopOpeningAngle[3]deg
\"refl5transangle\"= $refTopOpeningAngle[4]deg
\"refl5openangle\"= $refTopOpeningAngle[5]deg
\"refl5closedangle\"= $refTopOpeningAngle[6]deg
\"refl6angle\"= $refTopOpeningAngle[7]deg
\"lg1W\"= $dxLg[0]mm
\"lg2W\"= $dxLg[1]mm
\"lg3W\"= $dxLg[2]mm
\"lg4W\"= $dxLg[3]mm
\"lg5transW\"= $dxLg[4]mm
\"lg5openW\"= $dxLg[5]mm
\"lg5closedW\"= $dxLg[6]mm
\"lg6W\"= $dxLg[7]mm
\"lg1angle\"= $lgTiltAngle[0]deg
\"lg2angle\"= $lgTiltAngle[1]deg
\"lg3angle\"= $lgTiltAngle[2]deg
\"lg4angle\"= $lgTiltAngle[3]deg
\"lg5transangle\"= $lgTiltAngle[4]deg
\"lg5openangle\"= $lgTiltAngle[5]deg
\"lg5closedangle\"= $lgTiltAngle[6]deg
\"lg6angle\"= $lgTiltAngle[7]deg
\"lg1L\"= $dzLg[0]mm
\"lg2L\"= $dzLg[1]mm
\"lg3L\"= $dzLg[2]mm
\"lg4L\"= $dzLg[3]mm
\"lg5transL\"= $dzLg[4]mm
\"lg5openL\"= $dzLg[5]mm
\"lg5closedL\"= $dzLg[6]mm
\"lg6L\"= $dzLg[7]mm
\"D1\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl1L\"
\"D1\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl2L\"
\"D1\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl3L\"
\"D1\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl4L\"
\"D1\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"refl5openL\"
\"D1\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5closedL\"
\"D1\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl6L\"
\"D7\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl1angle\"
\"D7\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl2angle\"
\"D7\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl3angle\"
\"D7\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl4angle\"
\"D1\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5transL\"
\"D7\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5transangle\"
\"D7\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"refl5openangle\"
\"D7\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5closedangle\"
\"D7\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl6angle\"
\"D3\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1W\"
\"D3\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2W\"
\"D3\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3W\"
\"D3\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4W\"
\"D3\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5transW\"
\"D3\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5openW\"
\"D3\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closedW\"
\"D3\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6W\"
\"D5\@Sketch2\@R1_lightguide_single<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1L\"
\"D5\@Sketch2\@R2_lightguide_single<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2L\"
\"D5\@Sketch2\@R3_lightguide_single<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3L\"
\"D5\@Sketch2\@R4_lightguide_single<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4L\"
\"D5\@Sketch2\@R5trans_lightguide_single<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5transL\"
\"D5\@Sketch2\@R5open_lightguide_single<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5openL\"
\"D5\@Sketch2\@R5closed_lightguide_single<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closedL\"
\"D5\@Sketch2\@R6_lightguide_single<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6L\"
\"D2\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1angle\"
\"D2\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2angle\"
\"D2\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3angle\"
\"D2\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4angle\"
\"D2\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5transangle\"
\"D2\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5openangle\"
\"D2\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closedangle\"
\"D2\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6angle\"
\"q1thick\"= $dx[0]mm
\"q2thick\"= $dx[1]mm
\"q3thick\"= $dx[2]mm
\"q4thick\"= $dx[3]mm
\"q5transthick\"= $dx[4]mm
\"q5openthick\"= $dx[5]mm
\"q5closedthick\"= $dx[6]mm
\"q6thick\"= $dx[7]mm
\"lg1_wall_thickness\"= $dtWall[0]mm
\"lg2_wall_thickness\"= $dtWall[1]mm
\"lg3_wall_thickness\"= $dtWall[2]mm
\"lg4_wall_thickness\"= $dtWall[3]mm
\"lg5trans_wall_thickness\"= $dtWall[4]mm
\"lg5open_wall_thickness\"= $dtWall[5]mm
\"lg5closed_wall_thickness\"= $dtWall[6]mm
\"lg6_wall_thickness\"= $dtWall[7]mm
\"D1\@Boss-Extrude1\@R1_quartz<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"q1thick\"
\"D1\@Boss-Extrude1\@R2_quartz<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"q2thick\"
\"D1\@Boss-Extrude1\@R3_quartz<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"q3thick\"
\"D1\@Boss-Extrude1\@R4_quartz<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"q4thick\"
\"D1\@Boss-Extrude1\@R5trans_quartz<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5transthick\"
\"D1\@Boss-Extrude1\@R5open_quartz<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"q5openthick\"
\"D1\@Boss-Extrude1\@R5closed_quartz<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5closedthick\"
\"D1\@Boss-Extrude1\@R6_quartz<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"q6thick\"
\"D1\@Boss-Extrude1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1_wall_thickness\"
\"D1\@Boss-Extrude1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2_wall_thickness\"
\"D1\@Boss-Extrude1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3_wall_thickness\"
\"D1\@Boss-Extrude1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4_wall_thickness\"
\"D1\@Boss-Extrude1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5trans_wall_thickness\"
\"D1\@Boss-Extrude1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5open_wall_thickness\"
\"D1\@Boss-Extrude1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closed_wall_thickness\"
\"D1\@Boss-Extrude1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6_wall_thickness\"
\"PMT1d\"= $ddPmt[0]in
\"PMT2d\"= $ddPmt[1]in
\"PMT3d\"= $ddPmt[2]in
\"PMT4d\"= $ddPmt[3]in
\"PMT5transd\"= $ddPmt[4]in
\"PMT5opend\"= $ddPmt[5]in
\"PMT5closedd\"= $ddPmt[6]in
\"PMT6d\"= $ddPmt[7]in
\"PMT1L\"= $dzPmt[0]in
\"PMT2L\"= $dzPmt[1]in
\"PMT3L\"= $dzPmt[2]in
\"PMT4L\"= $dzPmt[3]in
\"PMT5transL\"= $dzPmt[4]in
\"PMT5openL\"= $dzPmt[5]in
\"PMT5closedL\"= $dzPmt[6]in
\"PMT6L\"= $dzPmt[7]in
\"D1\@Sketch1\@R1_3in_PMT<3>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT1d\"
\"D1\@Sketch1\@R2_3in_PMT<3>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT2d\"
\"D1\@Sketch1\@R3_3in_PMT<3>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT3d\"
\"D1\@Sketch1\@R4_3in_PMT<3>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT4d\"
\"D1\@Sketch1\@R5trans_3in_PMT<3>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5transd\"
\"D1\@Sketch1\@R5open_3in_PMT<3>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"PMT5opend\"
\"D1\@Sketch1\@R5closed_3in_PMT<3>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5closedd\"
\"D1\@Sketch1\@R6_3in_PMT<3>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT6d\"
\"D1\@Boss-Extrude1\@R1_3in_PMT<3>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT1L\"
\"D1\@Boss-Extrude1\@R2_3in_PMT<3>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT2L\"
\"D1\@Boss-Extrude1\@R3_3in_PMT<3>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT3L\"
\"D1\@Boss-Extrude1\@R4_3in_PMT<3>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT4L\"
\"D1\@Boss-Extrude1\@R5trans_3in_PMT<3>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5transL\"
\"D1\@Boss-Extrude1\@R5open_3in_PMT<3>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"PMT5openL\"
\"D1\@Boss-Extrude1\@R5closed_3in_PMT<3>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5closedL\"
\"D1\@Boss-Extrude1\@R6_3in_PMT<3>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT6L\"
\"q1roll\"= $roll[0]deg
\"q2roll\"= $roll[1]deg
\"q3roll\"= $roll[2]deg
\"q4roll\"= $roll[3]deg
\"q5transroll\"= $roll[4]deg
\"q5openroll\"= $roll[5]deg
\"q5closedroll\"= $roll[6]deg
\"q6roll\"= $roll[7]deg
\"D80\@skeleton\"=\"q1roll\"
\"D82\@skeleton\"=\"q1roll\"
\"D84\@skeleton\"=\"q2roll\"
\"D86\@skeleton\"=\"q2roll\"
\"D88\@skeleton\"=\"q3roll\"
\"D90\@skeleton\"=\"q3roll\"
\"D92\@skeleton\"=\"q4roll\"
\"D94\@skeleton\"=\"q4roll\"
\"D30\@skeleton\"=\"q5openroll\"
\"D24\@skeleton\"=\"q5openroll\"
\"D20\@skeleton\"=\"q5openroll\"
\"D15\@skeleton\"=\"q5transroll\"
\"D39\@skeleton\"=\"q5transroll\"
\"D10\@skeleton\"=\"q5transroll\"
\"D37\@skeleton\"=\"q5closedroll\"
\"D43\@skeleton\"=\"q5closedroll\"
\"D47\@skeleton\"=\"q5closedroll\"
\"D96\@skeleton\"=\"q6roll\"
\"D98\@skeleton\"=\"q6roll\"
\"q1stagger_z\"= $zstagger[0]mm
\"q1_z\"= $z[0]mm
\"q2stagger_z\"= $zstagger[1]mm
\"q2_z\"= $z[1]mm
\"q3stagger_z\"= $zstagger[2]mm
\"q3_z\"= $z[2]mm
\"q4stagger_z\"= $zstagger[3]mm
\"q4_z\"= $z[3]mm
\"q5transstagger_z\"= $zstagger[4]mm
\"q5trans_z\"= $z[4]mm
\"q5openstagger_z\"= $zstagger[5]mm
\"q5open_z\"= $z[5]mm
\"q5closedstagger_z\"= $zstagger[6]mm
\"q5closed_z\"= $z[6]mm
\"q6stagger_z\"= $zstagger[7]mm
\"q6_z\"= $z[7]mm
\"D51\@skeleton\"=\"q1stagger_z\"
\"D52\@skeleton\"=\"q1_z\"
\"D53\@skeleton\"=\"q2stagger_z\"
\"D54\@skeleton\"=\"q2_z\"
\"D55\@skeleton\"=\"q3stagger_z\"
\"D56\@skeleton\"=\"q3_z\"
\"D57\@skeleton\"=\"q4stagger_z\"
\"D58\@skeleton\"=\"q4_z\"
\"D33\@skeleton\"=\"q5closedstagger_z\"
\"D32\@skeleton\"=-\"q5closed_z\"
\"D31\@skeleton\"=\"q5closedstagger_z\"
\"D11\@skeleton\"=-\"q5trans_z\"
\"D48\@skeleton\"=\"q5transstagger_z\"
\"D5\@skeleton\"=-\"q5trans_z\"
\"D16\@skeleton\"=\"q5openstagger_z\"
\"D21\@skeleton\"=-\"q5open_z\"
\"D25\@skeleton\"=\"q5openstagger_z\"
\"D59\@skeleton\"=-\"q6stagger_z\"
\"D60\@skeleton\"=-\"q6_z\"";

close(def) or warn "close failed: $!";

#-----------------------------End writing equations.txt-------------------------------#

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
sub transt { 
my $k=shift; 
if($k%3==0){$k=$k*2;
}elsif($k%3==1){$k=($k-1)*2+1;
}else{ $k=($k-2)*2+2;
}
return $k;
}
sub opent { 
my $k=shift; 
if($k%3==0){$k=$k*4+3;
}elsif($k%3==1){$k=($k-1)*4+4;
}else{ $k=($k-2)*4+5;
}
return $k;
}
sub closedt { 
my $k=shift; 
if($k%3==0){$k=$k*4+9;
}elsif($k%3==1){$k=($k-1)*4+10;
}else{ $k=($k-2)*4+11;
}
return $k;
}

