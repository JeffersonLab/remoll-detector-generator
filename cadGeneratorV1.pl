: # feed this into perl *-*-perl-*-*
eval 'exec perl -S $0 "$@"'
  if $running_under_some_shell;

use Cwd;
use Cwd 'abs_path';
use File::Find ();
use File::Basename;
use Math::Trig;
use Getopt::Std;
use POSIX qw(modf fmod round);

##-------------------------------Declare variables explicitly so "my" not needed.------------------------------------##
use strict 'vars';
use vars
  qw($opt_F $data $line @fields @ring @z @zstagger @zDet @r @thetaDet @overlap @dx @dy @dz @tilt @roll @rollDet @rx @ry @rz @quartzCutAngle @refTopOpeningAngle @dzRef @dxLg @dyLg @height @dzLg  @lgTiltAngle @dxPmt @dyPmt @dzPmt @ddPmt @dtWall @extraPMTholderWidth @extraPMTholderDepth @dtReflector @numDet $i $thisring );
##-------------------------------------------------------------------------------------------------------------------##

##-------------------------------Get the option flags.------------------------------------------------------------------##
$opt_F = "cadp.csv";
getopts('F:');

if ( $#ARGV > -1 ) {
    print STDERR "Unknown arguments specified: @ARGV\nExiting.\n";
    exit;
}
##----------------------------------------------------------------------------------------------------------------------##

##-----------------------Start reading CSV file containing parameter values.---------------------------------##
open( $data, '<', $opt_F );    # Open csv file.

@numDet = ( 28, 28, 28, 28, 21, 42, 21, 28 )
  ;                            # Unelegant but needed placeholder for now.
$i = 0;

while ( $line = <$data> ) {    # Read each line till the end of the file.
    if ( $line =~ /^\s*$/ ) {    # Check for empty lines.
        print
          "String contains 0 or more white-space character and nothing else.\n";
    }
    else {
        chomp $line;
        @fields = split( ",", $line );    # Split the line into fields.
        $ring[$i] =
          trim( $fields[0] );    # Get rid of initial and trailing white spaces.
        $r[$i]  = trim( $fields[1] );    # Radial position of center of quartz.
        $dz[$i] = trim( $fields[2] );    # Length.
        $overlap[$i] =
          trim( $fields[3] );            # 0=minimum overlap, 1=maximum overlap.
        $dx[$i] = trim( $fields[4] );    # Thickness along beam direction.
        if ( $ring[$i] >= 5.0 && $ring[$i] < 6.0 ) {
            $dy[$i] =
              2 * pi *
              ( $r[$i] - ( $dz[$i] * ( 0.5 - $overlap[$i] ) ) ) /
              ( 4 * 7 *
                  3 ) # Calculating azimuthal width of detectors in moller ring.
        }
        else {
            $dy[$i] =
              2 * pi *
              ( $r[$i] - ( $dz[$i] * ( 0.5 - $overlap[$i] ) ) ) /
              ( 4 * 7
              )   # Calculating azimuthal width of detectors in all other rings.
        }
        $tilt[$i] = trim( $fields[5] );   # Tilt of quartz along beam direction.
        $roll[$i] =
          trim( $fields[6] );    # Roll about axis perpendicular to beam axis.
        $dzRef[$i] = trim( $fields[7] );    # Length of reflector section.
        $refTopOpeningAngle[$i] =
          trim( $fields[8] );               # Opening angle of reflector.
        $lgTiltAngle[$i] =
          trim( $fields[9] );               # Tilt of light guide wrt to quartz.
        $height[$i] =
          trim( $fields[10] );    # Starting radial position of PMTs (cathode)
        $ddPmt[$i]  = trim( $fields[11] );    # Diameter of PMT in inches
        $dzPmt[$i]  = trim( $fields[12] );    # Length of PMT
        $dtWall[$i] = trim( $fields[13] );    # Thickness of Wall
        $extraPMTholderWidth[$i] = trim( $fields[14] )
          ;    # Extra width of PMT holder (in addition to PMT diameter)
        $extraPMTholderDepth[$i] = trim( $fields[15] )
          ;    # Extra depth of PMT holder (in addition to PMT diameter)
        $z[$i]        = trim( $fields[16] );    # Z-position
        $zstagger[$i] = trim( $fields[17] );    # Staggered Z-position
        my $rad = pi / 180;                     # Radians for sin and cos
             # dxLg was field 10 (deleted), dzLg was previously parameter 11
        $dxLg[$i] = ( 25.4 * $ddPmt[$i] + $extraPMTholderWidth[$i] ) *
          cos( $rad * ( $tilt[$i] + $lgTiltAngle[$i] ) );

        # Width of reflector opening/lightguide segment
        $dzLg[$i] = (
            $height[$i] -
              $r[$i] -
              0.5 * (
                $dz[$i] * cos( $rad * $tilt[$i] ) +
                  $dx[$i] * sin( $rad * $tilt[$i] )
              ) -
              1 * $dzRef[$i] * cos( $rad * $refTopOpeningAngle[$i] ) +
              0.5 * $dxLg[$i] * sin( $rad * $lgTiltAngle[$i] )
          ) /
          cos( $rad * $lgTiltAngle[$i] );

# Length of Light Guide - the dzRef length computation also needs a dxRef*angle component (in this nomenclature it would be addition) so that the PMT placement in CAD solidworks will work out.
        $i = $i + 1;

    }
}

##----------------------------End reading CSV file containing parameter values.------------------------------------------##

##----------------------------Start writing parameter.csv for gdmlGenerator (Code works but lacks clarity. Need to check one to one correspondence between CAD and gdml azimuthal positioning.)----------------------------------------------##
open( def, ">", "parameter.csv" ) or die "cannot open > parameter.csv: $!";

for ( my $j = 0 ; $j < $i ; $j++ ) {
    print "ring $ring[$j]\n";

    for ( my $det = 0 ; $det < $numDet[$j] ; $det++ ) {

        # Determine this ring (and segment if ring 5)
        my ( $thisfrac, $thisring ) = POSIX::modf( $ring[$j] );
        $thisfrac = int( POSIX::round(10 * $thisfrac) );
        my $thissect = 1;

        # Modify theta for ring 5
        if ( $thisring == 5 && $thisfrac == 0 ) {
            ## subtract 1 more to fix phi-offset in ring 5 triply segmented open-transition-closed detector bunches - 3/2/2018 Cameron
            $thetaDet[$det] = 2 * pi * ( opent($det) - 1 ) / 84;
        }
        elsif ( $thisring == 5 && $thisfrac == 1 ) {
            $thetaDet[$det] = 2 * pi * ( transt($det) - 1 ) / 84;
        }
        elsif ( $thisring == 5 && $thisfrac == 2 ) {
            $thetaDet[$det] = 2 * pi * ( closedt($det) - 1 ) / 84;
        }
        else {
            $thetaDet[$det] = 2 * pi * $det / 28;
        }

        if ( $thisring == 5 ) {
            if ( $det % 3 == 1 )
            { ## modifying stagger assignment so that the central detector is forward in all open-transition-closed detector triple bunches - 3/2/2018 Cameron
                $zDet[$det] = $z[$j];
                ## If you want to make the open, transition or closed (4,5,6) actually have the central detector backward then change the first if statement here.
            }
            else {
                $zDet[$det] = $zstagger[$j];
            }
        }
        else {
            if ( $det % 2 == 0 ) {
                $zDet[$det] = $z[$j];
            }
            else {
                $zDet[$det] = $zstagger[$j];
            }
        }
        $rollDet[$det] = -1 * $roll[$j] + 90;
        my $dxPmt = $ddPmt[$j] * 25.4 + $extraPMTholderWidth[$j];
        my $dyPmt = $ddPmt[$j] * 25.4 + $extraPMTholderDepth[$j];

        my $thissept = int( $det * 7 / $numDet[$j] ) + 1;
        my $thiscoil = 0;
        if (($thisring != 5 && $det % ($numDet[$j] / 7) == 0) || ($thisring == 5 && $thisfrac == 2)) {
            $thiscoil = $thissept;
            $thissept = 0;
        }
        my $thissect = 0;
        if ($thiscoil == 0) {
            $thissect = $det % ($numDet[$j] / 7);
        }
        my $thisphi = 1;
        if ($thisring == 5) {
            $thissect = 2 - $thisfrac;
            $thisphi = $det % 3;
        }
        my $detno = $thisring*100000+$thissept*10000+$thiscoil*1000+$thissect*100+$thisphi*10;

        my $thetabase = ($thissept + $thiscoil - 1) * 2 * 180 / 7;
        my $thetadeg = $thetaDet[$det] * 180/pi;
        my $thetaseptdeg = POSIX::fmod($thetaDet[$det], 2*pi/7) * 180/pi;
        print "$detno at ", sprintf("%.2f",$thetadeg), " ( = ", sprintf("%.2f",$thetabase), " + ", sprintf("%.2f",$thetaseptdeg), " ) deg\n";
        print def "$detno, $zDet[$det], ${r[$j]*sin($thetaDet[$det])}, ${r[$j]*cos($thetaDet[$det])}, $dx[$j], $dy[$j], $dz[$j], $thetaDet[$det], ${tilt[$j]*pi/180}, ${rollDet[$det]*pi/180},  0.785398, ${refTopOpeningAngle[$j]*pi/180}, $dzRef[$j], $dxLg[$j], $dy[$j], $dzLg[$j], ${lgTiltAngle[$j]*pi/180}, $dxPmt, $dyPmt, ${dzPmt[$j]*25.4}, ${ddPmt[$j]*25.4/2}, $dtWall[$j], ${dtWall[$j]/5} \n";

    }
}

close(def) or warn "close failed: $!";
##-----------------------------------------------------------------------------------------------------------------------##

##--------------------------------------------Start writing equations.txt------------------------------------------------##

open( def, ">", "equations.txt" ) or die "cannot open > equations.txt: $!";
print def "\"D1\"=
\"q1L\"= $dz[0]mm
\"q2L\"= $dz[1]mm
\"q3L\"= $dz[2]mm
\"q4L\"= $dz[3]mm
\"q5openL\"= $dz[4]mm
\"q5transL\"= $dz[5]mm
\"q5closedL\"= $dz[6]mm
\"q6L\"= $dz[7]mm
\"q1r\"= $r[0]mm
\"q2r\"= $r[1]mm
\"q3r\"= $r[2]mm
\"q4r\"= $r[3]mm
\"q5openr\"= $r[4]mm
\"q5transr\"= $r[5]mm
\"q5closedr\"= $r[6]mm
\"q6r\"= $r[7]mm
\"q1W\"= $dy[0]mm
\"q2W\"= $dy[1]mm
\"q3W\"= $dy[2]mm
\"q4W\"= $dy[3]mm
\"q5openW\"= $dy[4]mm
\"q5transW\"= $dy[5]mm
\"q5closedW\"= $dy[6]mm
\"q6W\"= $dy[7]mm
\"q1tilt\"= $tilt[0]deg
\"q2tilt\"= $tilt[1]deg
\"q3tilt\"= $tilt[2]deg
\"q4tilt\"= $tilt[3]deg
\"q5opentilt\"= $tilt[4]deg
\"q5transtilt\"= $tilt[5]deg
\"q5closedtilt\"= $tilt[6]deg
\"q6tilt\"= $tilt[7]deg
\"refl1L\"= $dzRef[0]mm
\"refl2L\"= $dzRef[1]mm
\"refl3L\"= $dzRef[2]mm
\"refl4L\"= $dzRef[3]mm
\"refl5openL\"= $dzRef[4]mm
\"refl5transL\"= $dzRef[5]mm
\"refl5closedL\"= $dzRef[6]mm
\"refl6L\"= $dzRef[7]mm
\"refl1angle\"= $refTopOpeningAngle[0]deg
\"refl2angle\"= $refTopOpeningAngle[1]deg
\"refl3angle\"= $refTopOpeningAngle[2]deg
\"refl4angle\"= $refTopOpeningAngle[3]deg
\"refl5openangle\"= $refTopOpeningAngle[4]deg
\"refl5transangle\"= $refTopOpeningAngle[5]deg
\"refl5closedangle\"= $refTopOpeningAngle[6]deg
\"refl6angle\"= $refTopOpeningAngle[7]deg
\"lg1W\"= $dxLg[0]mm
\"lg2W\"= $dxLg[1]mm
\"lg3W\"= $dxLg[2]mm
\"lg4W\"= $dxLg[3]mm
\"lg5openW\"= $dxLg[4]mm
\"lg5transW\"= $dxLg[5]mm
\"lg5closedW\"= $dxLg[6]mm
\"lg6W\"= $dxLg[7]mm
\"lg1angle\"= $lgTiltAngle[0]deg
\"lg2angle\"= $lgTiltAngle[1]deg
\"lg3angle\"= $lgTiltAngle[2]deg
\"lg4angle\"= $lgTiltAngle[3]deg
\"lg5openangle\"= $lgTiltAngle[4]deg
\"lg5transangle\"= $lgTiltAngle[5]deg
\"lg5closedangle\"= $lgTiltAngle[6]deg
\"lg6angle\"= $lgTiltAngle[7]deg
\"PMTheight1\"= $height[0]mm
\"PMTheight2\"= $height[1]mm
\"PMTheight3\"= $height[2]mm
\"PMTheight4\"= $height[3]mm
\"PMTheight5open\"= $height[4]mm
\"PMTheight5trans\"= $height[5]mm
\"PMTheight5closed\"= $height[6]mm
\"PMTheight6\"= $height[7]mm
\"q1thick\"= $dx[0]mm
\"q2thick\"= $dx[1]mm
\"q3thick\"= $dx[2]mm
\"q4thick\"= $dx[3]mm
\"q5openthick\"= $dx[4]mm
\"q5transthick\"= $dx[5]mm
\"q5closedthick\"= $dx[6]mm
\"q6thick\"= $dx[7]mm
\"lg1_wall_thickness\"= $dtWall[0]mm
\"lg2_wall_thickness\"= $dtWall[1]mm
\"lg3_wall_thickness\"= $dtWall[2]mm
\"lg4_wall_thickness\"= $dtWall[3]mm
\"lg5open_wall_thickness\"= $dtWall[4]mm
\"lg5trans_wall_thickness\"= $dtWall[5]mm
\"lg5closed_wall_thickness\"= $dtWall[6]mm
\"lg6_wall_thickness\"= $dtWall[7]mm
\"PMT1d\"= $ddPmt[0]in
\"PMT2d\"= $ddPmt[1]in
\"PMT3d\"= $ddPmt[2]in
\"PMT4d\"= $ddPmt[3]in
\"PMT5opend\"= $ddPmt[4]in
\"PMT5transd\"= $ddPmt[5]in
\"PMT5closedd\"= $ddPmt[6]in
\"PMT6d\"= $ddPmt[7]in
\"PMT1L\"= $dzPmt[0]in
\"PMT2L\"= $dzPmt[1]in
\"PMT3L\"= $dzPmt[2]in
\"PMT4L\"= $dzPmt[3]in
\"PMT5openL\"= $dzPmt[4]in
\"PMT5transL\"= $dzPmt[5]in
\"PMT5closedL\"= $dzPmt[6]in
\"PMT6L\"= $dzPmt[7]in
\"q1roll\"= $roll[0]deg
\"q2roll\"= $roll[1]deg
\"q3roll\"= $roll[2]deg
\"q4roll\"= $roll[3]deg
\"q5openroll\"= $roll[4]deg
\"q5transroll\"= $roll[5]deg
\"q5closedroll\"= $roll[6]deg
\"q6roll\"= $roll[7]deg
\"q1stagger_z\"= $zstagger[0]mm
\"q1_z\"= $z[0]mm
\"q2stagger_z\"= $zstagger[1]mm
\"q2_z\"= $z[1]mm
\"q3stagger_z\"= $zstagger[2]mm
\"q3_z\"= $z[2]mm
\"q4stagger_z\"= $zstagger[3]mm
\"q4_z\"= $z[3]mm
\"q5openstagger_z\"= $zstagger[4]mm
\"q5open_z\"= $z[4]mm
\"q5transstagger_z\"= $zstagger[5]mm
\"q5trans_z\"= $z[5]mm
\"q5closedstagger_z\"= $zstagger[6]mm
\"q5closed_z\"= $z[6]mm
\"q6stagger_z\"= $zstagger[7]mm
\"q6_z\"= $z[7]mm
\"PMTholder1_extra_width\"= $extraPMTholderWidth[0]mm
\"PMTholder2_extra_width\"= $extraPMTholderWidth[1]mm
\"PMTholder3_extra_width\"= $extraPMTholderWidth[2]mm
\"PMTholder4_extra_width\"= $extraPMTholderWidth[3]mm
\"PMTholder5open_extra_width\"= $extraPMTholderWidth[4]mm
\"PMTholder5trans_extra_width\"= $extraPMTholderWidth[5]mm
\"PMTholder5closed_extra_width\"= $extraPMTholderWidth[6]mm
\"PMTholder6_extra_width\"= $extraPMTholderWidth[7]mm
\"PMTholder1_extra_depth\"= $extraPMTholderDepth[0]mm
\"PMTholder2_extra_depth\"= $extraPMTholderDepth[1]mm
\"PMTholder3_extra_depth\"= $extraPMTholderDepth[2]mm
\"PMTholder4_extra_depth\"= $extraPMTholderDepth[3]mm
\"PMTholder5open_extra_depth\"= $extraPMTholderDepth[4]mm
\"PMTholder5trans_extra_depth\"= $extraPMTholderDepth[5]mm
\"PMTholder5closed_extra_depth\"= $extraPMTholderDepth[6]mm
\"PMTholder6_extra_depth\"= $extraPMTholderDepth[7]mm
\"lg1L\"= $dzLg[0]mm
\"lg2L\"= $dzLg[1]mm
\"lg3L\"= $dzLg[2]mm
\"lg4L\"= $dzLg[3]mm
\"lg5openL\"= $dzLg[4]mm
\"lg5transL\"= $dzLg[5]mm
\"lg5closedL\"= $dzLg[6]mm
\"lg6L\"= $dzLg[7]mm
\"D1\@Sketch1\@R1_quartz<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"q1W\"
\"D1\@Sketch1\@R2_quartz<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"q2W\"
\"D1\@Sketch1\@R3_quartz<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"q3W\"
\"D1\@Sketch1\@R4_quartz<1>.Part\@R4_quartz_lg_reflector_assembly<3>.Assembly\" = \"q4W\"
\"D1\@Sketch1\@R5open_quartz<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"q5openW\"
\"D1\@Sketch1\@R5trans_quartz<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5transW\"
\"D1\@Sketch1\@R5closed_quartz<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5closedW\"
\"D1\@Sketch1\@R6_quartz<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"q6W\"
\"D2\@Sketch1\@R1_quartz<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"q1L\"
\"D2\@Sketch1\@R2_quartz<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"q2L\"
\"D2\@Sketch1\@R3_quartz<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"q3L\"
\"D2\@Sketch1\@R4_quartz<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"q4L\"
\"D2\@Sketch1\@R5open_quartz<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"q5openL\"
\"D2\@Sketch1\@R5trans_quartz<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5transL\"
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
\"D19\@skeleton\"=\"q5opentilt\"
\"D28\@skeleton\"=\"q5opentilt\"
\"D29\@skeleton\"=\"q5opentilt\"
\"D9\@skeleton\"=\"q5transtilt\"
\"D38\@skeleton\"=\"q5transtilt\"
\"D14\@skeleton\"=\"q5transtilt\"
\"D46\@skeleton\"=\"q5closedtilt\"
\"D42\@skeleton\"=\"q5closedtilt\"
\"D36\@skeleton\"=\"q5closedtilt\"
\"D95\@skeleton\"=\"q6tilt\"
\"D97\@skeleton\"=\"q6tilt\"
\"D1\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl1L\"
\"D1\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl2L\"
\"D1\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl3L\"
\"D1\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl4L\"
\"D1\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"refl5openL\"
\"D1\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5transL\"
\"D1\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5closedL\"
\"D1\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl6L\"
\"D7\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl1angle\"
\"D7\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl2angle\"
\"D7\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl3angle\"
\"D7\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl4angle\"
\"D7\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"refl5openangle\"
\"D7\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5transangle\"
\"D7\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl5closedangle\"
\"D7\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"refl6angle\"
\"D3\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1W\"
\"D3\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2W\"
\"D3\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3W\"
\"D3\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4W\"
\"D3\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5openW\"
\"D3\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5transW\"
\"D3\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closedW\"
\"D3\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6W\"
\"D5\@Sketch2\@R1_lightguide_single<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1L\"
\"D5\@Sketch2\@R2_lightguide_single<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2L\"
\"D5\@Sketch2\@R3_lightguide_single<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3L\"
\"D5\@Sketch2\@R4_lightguide_single<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4L\"
\"D5\@Sketch2\@R5open_lightguide_single<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5openL\"
\"D5\@Sketch2\@R5trans_lightguide_single<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5transL\"
\"D5\@Sketch2\@R5closed_lightguide_single<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closedL\"
\"D5\@Sketch2\@R6_lightguide_single<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6L\"
\"D2\@Sketch1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1angle\"
\"D2\@Sketch1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2angle\"
\"D2\@Sketch1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3angle\"
\"D2\@Sketch1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4angle\"
\"D2\@Sketch1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5openangle\"
\"D2\@Sketch1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5transangle\"
\"D2\@Sketch1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closedangle\"
\"D2\@Sketch1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6angle\"
\"D1\@Boss-Extrude1\@R1_quartz<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"q1thick\"
\"D1\@Boss-Extrude1\@R2_quartz<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"q2thick\"
\"D1\@Boss-Extrude1\@R3_quartz<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"q3thick\"
\"D1\@Boss-Extrude1\@R4_quartz<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"q4thick\"
\"D1\@Boss-Extrude1\@R5open_quartz<1>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"q5openthick\"
\"D1\@Boss-Extrude1\@R5trans_quartz<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5transthick\"
\"D1\@Boss-Extrude1\@R5closed_quartz<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"q5closedthick\"
\"D1\@Boss-Extrude1\@R6_quartz<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"q6thick\"
\"D1\@Boss-Extrude1\@R1_reflector_side_wall<3>.Part\@R1_reflector<1>.Assembly\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg1_wall_thickness\"
\"D1\@Boss-Extrude1\@R2_reflector_side_wall<3>.Part\@R2_reflector<1>.Assembly\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg2_wall_thickness\"
\"D1\@Boss-Extrude1\@R3_reflector_side_wall<3>.Part\@R3_reflector<1>.Assembly\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg3_wall_thickness\"
\"D1\@Boss-Extrude1\@R4_reflector_side_wall<3>.Part\@R4_reflector<1>.Assembly\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg4_wall_thickness\"
\"D1\@Boss-Extrude1\@R5open_reflector_side_wall<3>.Part\@R5open_reflector<1>.Assembly\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"lg5open_wall_thickness\"
\"D1\@Boss-Extrude1\@R5trans_reflector_side_wall<3>.Part\@R5trans_reflector<1>.Assembly\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5trans_wall_thickness\"
\"D1\@Boss-Extrude1\@R5closed_reflector_side_wall<3>.Part\@R5closed_reflector<1>.Assembly\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg5closed_wall_thickness\"
\"D1\@Boss-Extrude1\@R6_reflector_side_wall<3>.Part\@R6_reflector<1>.Assembly\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"lg6_wall_thickness\"
\"D1\@Sketch1\@R1_3in_PMT<3>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT1d\"
\"D1\@Sketch1\@R2_3in_PMT<3>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT2d\"
\"D1\@Sketch1\@R3_3in_PMT<3>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT3d\"
\"D1\@Sketch1\@R4_3in_PMT<3>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT4d\"
\"D1\@Sketch1\@R5open_3in_PMT<3>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"PMT5opend\"
\"D1\@Sketch1\@R5trans_3in_PMT<3>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5transd\"
\"D1\@Sketch1\@R5closed_3in_PMT<3>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5closedd\"
\"D1\@Sketch1\@R6_3in_PMT<3>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT6d\"
\"D1\@Boss-Extrude1\@R1_3in_PMT<3>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT1L\"
\"D1\@Boss-Extrude1\@R2_3in_PMT<3>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT2L\"
\"D1\@Boss-Extrude1\@R3_3in_PMT<3>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT3L\"
\"D1\@Boss-Extrude1\@R4_3in_PMT<3>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT4L\"
\"D1\@Boss-Extrude1\@R5open_3in_PMT<3>.Part\@R5open_quartz_lg_reflector_assembly<2>.Assembly\" = \"PMT5openL\"
\"D1\@Boss-Extrude1\@R5trans_3in_PMT<3>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5transL\"
\"D1\@Boss-Extrude1\@R5closed_3in_PMT<3>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT5closedL\"
\"D1\@Boss-Extrude1\@R6_3in_PMT<3>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = \"PMT6L\"
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
\"D51\@skeleton\"=\"q1stagger_z\"
\"D52\@skeleton\"=\"q1_z\"
\"D53\@skeleton\"=\"q2stagger_z\"
\"D54\@skeleton\"=\"q2_z\"
\"D55\@skeleton\"=\"q3stagger_z\"
\"D56\@skeleton\"=\"q3_z\"
\"D57\@skeleton\"=\"q4stagger_z\"
\"D58\@skeleton\"=\"q4_z\"
\"D16\@skeleton\"=\"q5openstagger_z\"
\"D21\@skeleton\"=-\"q5open_z\"
\"D25\@skeleton\"=\"q5openstagger_z\"
\"D11\@skeleton\"=\"q5transstagger_z\"
\"D48\@skeleton\"=\"q5trans_z\"
\"D5\@skeleton\"=\"q5transstagger_z\"
\"D33\@skeleton\"=\"q5closedstagger_z\"
\"D32\@skeleton\"=-\"q5closed_z\" 
\"D31\@skeleton\"=\"q5closedstagger_z\"
\"D59\@skeleton\"=-\"q6stagger_z\"
\"D60\@skeleton\"=-\"q6_z\"
\"D2\@Sketch1\@R1_PMT_holder<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R1_3in_PMT<3>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder1_extra_width\"
\"D2\@Sketch1\@R2_PMT_holder<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R2_3in_PMT<3>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder2_extra_width\"
\"D2\@Sketch1\@R3_PMT_holder<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R3_3in_PMT<3>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder3_extra_width\"
\"D2\@Sketch1\@R4_PMT_holder<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R4_3in_PMT<3>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder4_extra_width\"
\"D2\@Sketch1\@R5open_PMT_holder<1>.Part\@R5open_quartz_lg_reflector_assembly<3>.Assembly\"=\"D1\@Sketch1\@R5open_3in_PMT<3>.Part\@R5open_quartz_lg_reflector_assembly<3>.Assembly\" + \"PMTholder5open_extra_width\"
\"D2\@Sketch1\@R5trans_PMT_holder<1>.Part\@R5trans_quartz_lg_reflector_assembly<3>.Assembly\"=\"D1\@Sketch1\@R5trans_3in_PMT<3>.Part\@R5trans_quartz_lg_reflector_assembly<2>.Assembly\" + \"PMTholder5trans_extra_width\"
\"D2\@Sketch1\@R5closed_PMT_holder<1>.Part\@R5closed_quartz_lg_reflector_assembly<2>.Assembly\"=\"D1\@Sketch1\@R5closed_3in_PMT<3>.Part\@R5closed_quartz_lg_reflector_assembly<2>.Assembly\" + \"PMTholder5closed_extra_width\"
\"D2\@Sketch1\@R6_PMT_holder<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R6_3in_PMT<3>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder6_extra_width\"
\"D1\@Sketch1\@R1_PMT_holder<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R1_3in_PMT<3>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder1_extra_depth\"
\"D1\@Sketch1\@R2_PMT_holder<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R2_3in_PMT<3>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder2_extra_depth\"
\"D1\@Sketch1\@R3_PMT_holder<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R3_3in_PMT<3>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder3_extra_depth\"
\"D1\@Sketch1\@R4_PMT_holder<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R4_3in_PMT<3>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder4_extra_depth\"
\"D1\@Sketch1\@R5open_PMT_holder<1>.Part\@R5open_quartz_lg_reflector_assembly<3>.Assembly\"=\"D1\@Sketch1\@R5open_3in_PMT<3>.Part\@R5open_quartz_lg_reflector_assembly<3>.Assembly\" + \"PMTholder5open_extra_depth\"
\"D1\@Sketch1\@R5trans_PMT_holder<1>.Part\@R5trans_quartz_lg_reflector_assembly<3>.Assembly\"=\"D1\@Sketch1\@R5trans_3in_PMT<3>.Part\@R5trans_quartz_lg_reflector_assembly<3>.Assembly\" + \"PMTholder5trans_extra_depth\"
\"D1\@Sketch1\@R5closed_PMT_holder<1>.Part\@R5closed_quartz_lg_reflector_assembly<2>.Assembly\"=\"D1\@Sketch1\@R5closed_3in_PMT<3>.Part\@R5closed_quartz_lg_reflector_assembly<2>.Assembly\" + \"PMTholder5closed_extra_depth\"
\"D1\@Sketch1\@R6_PMT_holder<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\"=\"D1\@Sketch1\@R6_3in_PMT<3>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" + \"PMTholder6_extra_depth\"
\"D1\@Sketch2\@R1_lightguide_single<1>.Part\@R1_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q1tilt\" - \"lg1angle\"
\"D1\@Sketch2\@R2_lightguide_single<1>.Part\@R2_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q2tilt\" - \"lg2angle\"
\"D1\@Sketch2\@R3_lightguide_single<1>.Part\@R3_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q3tilt\" - \"lg3angle\"
\"D1\@Sketch2\@R4_lightguide_single<1>.Part\@R4_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q4tilt\" - \"lg4angle\"
\"D1\@Sketch2\@R5open_lightguide_single<1>.Part\@R5open_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q5opentilt\" - \"lg5closedangle\"
\"D1\@Sketch2\@R5trans_lightguide_single<1>.Part\@R5trans_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q5transtilt\" - \"lg5transangle\"
\"D1\@Sketch2\@R5closed_lightguide_single<1>.Part\@R5closed_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q5closedtilt\" - \"lg5closedangle\"
\"D1\@Sketch2\@R6_lightguide_single<1>.Part\@R6_quartz_lg_reflector_assembly<1>.Assembly\" = 90.00deg - \"q6tilt\" - \"lg6angle\"";

close(def) or warn "close failed: $!";

#-----------------------------End writing equations.txt-------------------------------#

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s }
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s }
sub trim  { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s }

sub opent {
    my $det = shift;
    if ( $det % 3 == 0 ) {
        $det = $det * 4 + 6;
    }
    elsif ( $det % 3 == 1 ) {
        $det = ( $det - 1 ) * 4 + 7;
    }
    else {
        $det = ( $det - 2 ) * 4 + 8;
    }
    return $det;
}

sub transt {
    my $det = shift;
    if ( $det % 3 == 0 ) {
        $det = $det * 2 + 3;
    }
    elsif ( $det % 3 == 1 ) {
        $det = ( $det - 1 ) * 2 + 4;
    }
    else {
        $det = ( $det - 2 ) * 2 + 5;
    }
    return $det;
}

sub closedt {
    my $det = shift;
    if ( $det % 3 == 0 ) {
        $det = $det * 4;
    }
    elsif ( $det % 3 == 1 ) {
        $det = ( $det - 1 ) * 4 + 1;
    }
    else {
        $det = ( $det - 2 ) * 4 + 2;
    }
    return $det;
}

