: # feed this into perl *-*-perl-*-*
eval 'exec perl -S $0 "$@"'
  if $running_under_some_shell;

use Cwd;
use Cwd 'abs_path';
use File::Find ();
use File::Basename;
use Math::Trig;
use Getopt::Std;

# Version 1 = PMT housing outside light guide.

##------------------Declare variables explicitly so "my" not needed.----------------##
use strict 'vars';
use vars
  qw($opt_L $opt_I $mylar @MylarReflectivity $uvs @Efficiency4 @Reflect_LG $inref @Reflectivity3 @Reflectivity4 @PhotonEnergy @RefractiveIndex1 @RefractiveIndex2 @RefractiveIndex3 @RefractiveIndexAR @RefractiveIndexN2 @RefractiveIndexCO2 @Absorption1 $opt_M $opt_D $opt_T $opt_P $opt_U $opt_R $opt_MYLAR $data $line @fields $dxM $dyM $dzM $drMinM $dxMext @index @x @y @z @dx @dy @dz @rx @ry @rz @quartzCutAngle @refTopOpeningAngle @dzRef @dxLg @dyLg @dzLg @dzLgExtra @lgTiltAngle @dxPmt @dyPmt @dzPmt @drPmt @dtWall @dtReflector $opt_i $opt_j $opt_t $opt_p $i $j $k $o $angle1 $angle2 @parallelQuartzRCenter @parallelQuartzRExtent @parallelReflectorRExtent @parallelPmtRStart $parallelDetPlaneThickness @fullLength);
##----------------------------------------------------------------------------------##

##------------------Get the option flags and set defaults---------------------------##

$opt_M = "detectorMotherP.csv";    #Mother Volume csv
$opt_D = "parameter.csv";          #Detector Volume csv
$opt_T = "";                       #Changes suffix
$opt_P = "qe.txt";                 #Photon energy vs property file
$opt_U = "UVS_45total.txt";        #Wavelength vs reflectivity file
$opt_R = "MylarRef.txt";           #Mylar Wavelength vs reflectivity file
$opt_L = "";  # If nonempty draw single detector of specified ring
$opt_I = "";  # If nonempty use inline PMT option
$opt_i = "5"; # Which reflector length square (from 0 to 10)
$opt_j = "5"; # Which reflector width square (from 0 to 10) 
$opt_t = "0"; # Angle in degrees to rotate normal towards quartz bevel
$opt_p = "0"; # Angle in degrees to rotate normal perpendicular to theta

getopts('M:D:T:P:U:R:L:I:i:j:t:p:');

if ( $#ARGV > -1 ) {
    print STDERR "Unknown arguments specified: @ARGV\nExiting.\n";
    exit;
}
##----------------------------------------------------------------------------------##

##------------------Start Reading CSV file containing parameter values for mother volume.-------------##
open( $data, '<', $opt_M );    # Open csv file.
$i = 0;
while ( $line = <$data> ) {    # Read each line till the end of the file.
    if ( $line =~ /^\s*$/ ) {    # Check for empty lines.
        print
          "String contains 0 or more white-space character and nothing else.\n";
    }
    else {
        chomp $line;
        @fields = split( ",", $line );    # Split the line into fields.
        $dxM =
          trim( $fields[0] );    # Get rid of initial and trailing white spaces.
        $dyM    = trim( $fields[1] );
        $dzM    = trim( $fields[2] );
        $drMinM = trim( $fields[3] );
        $dxMext = trim( $fields[4] );
        $i      = $i + 1;
    }
}
close $data;
##----------------------------------------------------------------------------------------------------##

##------------------Start Reading CSV file containing parameter values for detectors inside mother volume.-------------##
open( $data, '<', $opt_D );      # Open csv file.
$i = 0;
while ( $line = <$data> ) {      # Read each line till the end of the file.
    if ( $line =~ /^\s*$/ ) {    # Check for empty lines.
        print
          "String contains 0 or more white-space character and nothing else.\n";
    }
    else {
        chomp $line;
        @fields = split( ",", $line );    # Split the line into fields.
        if ( $opt_L ne "" ) {
            if (
                index( $opt_L, "5" ) >= 0
                && (
                    index( $opt_L, "open" ) >= 0
                    || (   index( $opt_L, "closed" ) < 0
                        && index( $opt_L, "trans" ) < 0 )
                )
                && substr( trim( $fields[0] ), 0, 6 ) == "540210"
              )
            {
            }
            elsif (index( $opt_L, "5" ) >= 0
                && index( $opt_L, "trans" ) >= 0
                && substr( trim( $fields[0] ), 0, 6 ) == "540110" )
            {
            }
            elsif (index( $opt_L, "5" ) >= 0
                && index( $opt_L, "closed" ) >= 0
                && substr( trim( $fields[0] ), 0, 6 ) == "504010" )
            {
            }
            elsif (
                #   index( $opt_L, substr( trim( $fields[0] ), 0, 1 ) ) >= 0
                #&& substr( trim( $fields[0] ), 0, 1 ) != "5"
                #&& (
                    ( ( $opt_L == "" || index( $opt_L, "5") < 0 ) && ( # Check if it has no specific ring number or is not ring 5
                        (
                        index( $opt_L, "trans" ) >= 0
                        && substr( trim( $fields[0] ), 1, 3 ) == "401"
                    )
                    || (
                        (
                            index( $opt_L, "open" ) >= 0 
                             || (   index( $opt_L, "closed" ) < 0
                                 && index( $opt_L, "trans" ) < 0 
                                 && index( $opt_L, substr( trim( $fields[0] ), 0, 1 ) ) >= 0 )
                        )
                        && substr( trim( $fields[0] ), 1, 3 ) == "402"
                    )
                    || ( index( $opt_L, "closed" ) >= 0
                        && substr( trim( $fields[0] ), 1, 3 ) == "040" )
                )))
                #)
            {
            }
            else {
                next;
            }
        }

        $index[$i] =
          trim( $fields[0] );    # Get rid of initial and trailing white spaces.
        $x[$i]                  = trim( $fields[1] );
        $y[$i]                  = trim( $fields[2] );
        $z[$i]                  = trim( $fields[3] );
        $dx[$i]                 = trim( $fields[4] ); 
        $dy[$i]                 = trim( $fields[5] ); 
        $dz[$i]                 = trim( $fields[6] ); 
        $rx[$i]                 = trim( $fields[7] );  # Theta
        $ry[$i]                 = trim( $fields[8] );  # Tilt
        $rz[$i]                 = trim( $fields[9] );  # Roll
        $quartzCutAngle[$i]     = trim( $fields[10] );
        $refTopOpeningAngle[$i] = trim( $fields[11] ); # Reflector top opening angle
        $dzRef[$i]              = trim( $fields[12] );
        $dxLg[$i]               = trim( $fields[13] );
        $dyLg[$i]               = trim( $fields[14] );
        $dzLg[$i]               = trim( $fields[15] );
        $lgTiltAngle[$i]        = trim( $fields[16] );
        $dxPmt[$i]              = trim( $fields[17] );
        $dyPmt[$i]              = trim( $fields[18] );
        $dzPmt[$i]              = trim( $fields[19] ); # PMT length
        $drPmt[$i]              = trim( $fields[20] ); # PMT radius
        $dtWall[$i]             = trim( $fields[21] ); # lg, ref wall thickness
        $dtReflector[$i]        = trim( $fields[22] ); # reflector thickness = 1/5 x dtWall (default)
        #4 new numbers, r, quartz radial extent (projected onto xy plane), reflector radial extent (projected onto xy plane), height in xy plane at which PMT resides
        $parallelQuartzRCenter[$i]    = trim( $fields[23] );
        $parallelQuartzRExtent[$i]    = trim( $fields[24] );
        $parallelReflectorRExtent[$i] = trim( $fields[25] );
        $parallelPmtRStart[$i]        = trim( $fields[26] );
        $dzLgExtra[$i] =
          ( 0.55 * $dxPmt[$i] ) * sin( $lgTiltAngle[$i] + $ry[$i] );
        $i = $i + 1;
    }
}
close $data;
##-------------------------------------------------------------------------------##

##------------------Start Photon Energy File (Brad's Data)-----------------------##

open( $data,  '<', $opt_P );    # Open space seperated value file.
open( $uvs,   '<', $opt_U );
open( $mylar, '<', $opt_R );
$o = 0;
while ( $line = <$data> ) {     # Read each line till the end of the file.
    if ( $line =~ /^\s*$/ ) {    # Check for empty lines.
        print
          "String contains 0 or more white-space character and nothing else.\n";
    }
    else {
        chomp $line;
        @fields = split( " ", $line );    # Split the line into fields.
        $PhotonEnergy[$o] = 1240.7 / trim( $fields[0] )
          ; #(300000000.0/(pow(10, -9)* file_input ))*(4.135667*pow(10, -15))            # Get rid of initial and trailing white spaces.
        $Efficiency4[$o] = trim( $fields[1] ) / 100;
##------------------Do the relevant calculations in the same loop----------------##
        $RefractiveIndex1[$o] = 1.455 - ( .005836 * $PhotonEnergy[$o] ) +
          ( .003374 * $PhotonEnergy[$o] * $PhotonEnergy[$o] );
        $Absorption1[$o] =
          exp(4.325) *
          exp( 1.191 * $PhotonEnergy[$o] ) *
          exp( -.213 * $PhotonEnergy[$o] * $PhotonEnergy[$o] ) *
          exp(
            -.04086 * $PhotonEnergy[$o] * $PhotonEnergy[$o] * $PhotonEnergy[$o]
          );
        if ( $Absorption1[$o] > 25 ) { $Absorption1[$o] = 25; }
        my $wavelength = 1.2398 / $PhotonEnergy[$o];
        my $wav        = $wavelength**-2;
        # Air refractive index, important to get Cherenkov production right
        $RefractiveIndex2[$o] = 1 + ( .05792105 / ( 238.0185 - $wav ) ) +
          ( .00167917 / ( 57.362 - $wav ) );
        # FIXME the PMT properties may be important later - details included in qsim code/people have numbers
        $RefractiveIndex3[$o] = 0;
        $Reflectivity4[$o]    = 0;
        $RefractiveIndexAR[$o] =
          1 + ( 2.50141 * ( 10.**-3 ) / ( 91.012 - $wav ) ) +
          ( 5.00283 * ( 10.**-4 ) / ( 87.892 - $wav ) ) +
          ( 5.22343 * ( 10.**-2 ) / ( 214.02 - $wav ) );
        $RefractiveIndexN2[$o] = 1 + ( 6.8552 * ( 10.**-5 ) ) +
          ( 3.243157 * ( 10.**-2 ) / ( 144 - $wav ) );
        $RefractiveIndexCO2[$o] =
          1 + ( 6.991 * ( 10.**-2 ) / ( 166.175 - $wav ) ) +
          ( 1.4472 *  ( 10.**-3 ) / ( 79.609 - $wav ) ) +
          ( 6.42941 * ( 10.**-5 ) / ( 56.3064 - $wav ) ) +
          ( 5.21306 * ( 10.**-5 ) / ( 46.0196 - $wav ) ) +
          ( 1.46847 * ( 10.**-6 ) / ( .0584738 - $wav ) );

          # FIXME this will be a tuned parameter eventually. 0.9 is optimistically high
        $Reflect_LG[$o] = .7;
##-----------------Read from the UVS file----------------------------------------##

        do {
            $line = <$uvs>;
            if ( $line =~ /^\s*$/ ) {    # Check for empty lines.
                print
"String contains 0 or more white-space character and nothing else.\n";
            }
            else {
                @fields = split( " ", $line );
                my $inwav = trim( $fields[0] );
                $inref = trim( $fields[1] );
            }
        } while ( inwav < ( 1000 * wavelength ) );

        $Reflectivity3[$o] = $inref;
##-----------------Read from the Mylar file----------------------------------------##
        $line = <$mylar>;    # Skip header line
        do {
            $line = <$mylar>;
            if ( $line =~ /^\s*$/ ) {    # Check for empty lines.
                print
"String contains 0 or more white-space character and nothing else.\n";
            }
            else {
                @fields = split( " ", $line );
                my $inwav = trim( $fields[0] );
                $inref = trim( $fields[3] );
            }
        } while ( inwav < ( 1000 * wavelength ) );
        $MylarReflectivity[$o] = $inref;

##-----------------Add the relevant units as a string to be parsed by GDML-------##

        $PhotonEnergy[$o] = $PhotonEnergy[$o] . "*eV";
        $Absorption1[$o]  = $Absorption1[$o] . "*m";

        $o = $o + 1;
    }
}
close $data;
close $uvs;
close $mylar;
##--------------------Hard Coded atrices----------------------------------------##

my @Scnt_PP   = ( "2.*eV", "6*eV" );
my @Scnt_FAST = ( 0.5,     0.5 );
my @Scnt_SLOW = ( 0.5,     0.5 );

my @Ephoton         = ( "2.038*eV", "4.144*eV" );
my @RefractiveIndex = ( 1.46,       1.46 );
my @SpecularLobe    = ( 0.3,        0.3 );
my @SpecularSpike   = ( 0.2,        0.2 );
my @Backscatter     = ( 0.2,        0.2 );

my @PhotonEC = (
    "2.04358*eV", "2.0664*eV",  "2.09046*eV", "2.14023*eV",
    "2.16601*eV", "2.20587*eV", "2.23327*eV", "2.26137*eV",
    "2.31972*eV", "2.35005*eV", "2.38116*eV", "2.41313*eV",
    "2.44598*eV", "2.47968*eV", "2.53081*eV", "2.58354*eV",
    "2.6194*eV",  "2.69589*eV", "2.73515*eV", "2.79685*eV",
    "2.86139*eV", "2.95271*eV", "3.04884*eV", "3.12665*eV",
    "3.2393*eV",  "3.39218*eV", "3.52508*eV", "3.66893*eV",
    "3.82396*eV", "3.99949*eV", "4.13281*eV", "4.27679*eV",
    "4.48244*eV", "4.65057*eV", "4.89476*eV", "5.02774*eV",
    "5.16816*eV", "5.31437*eV", "5.63821*eV", "5.90401*eV",
    "6.19921*eV"
);
my @CO2_1atm_AbsLen = (
    "70316.5*m", "66796.2*m", "63314.0*m", "56785.7*m",
    "53726.5*m", "49381.2*m", "46640.7*m", "44020.0*m",
    "39127.2*m", "36845.7*m", "34671.4*m", "32597.4*m",
    "30621.3*m", "28743.4*m", "26154.3*m", "23775.1*m",
    "22306.7*m", "19526.3*m", "18263.4*m", "16473.0*m",
    "14823.5*m", "12818.8*m", "11053.4*m", "9837.32*m",
    "8351.83*m", "6747.67*m", "5648.87*m", "4694.87*m",
    "3876.99*m", "3150.27*m", "2706.97*m", "2310.46*m",
    "1859.36*m", "1568.2*m",  "1237.69*m", "1093.38*m",
    "962.586*m", "846.065*m", "643.562*m", "520.072*m",
    "133.014*m"
);

##--------------------Write to mollerMother.gdml file----------------------------------------##

open( def, ">", "mollerMother${opt_T}.gdml" )
  or die "cannot open > mollerMother${opt_T}.gdml: $!";
print def "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>

<gdml xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"http://service-spi.web.cern.ch/service-spi/app/releases/GDML/schema/gdml.xsd\">

<define> 
  <position name=\"detectorCenter\" x=\"0\" y=\"0\" z=\"125.0 + 0.0*28500.\"/>
  <rotation name=\"identity\"/>
  <rotation name=\"rot\" unit=\"deg\" x=\"0\" y=\"90\" z=\"0\"/>
</define>

<materials>
     <material Z=\"1\" name=\"Vacuum\" state=\"gas\">
       <T unit=\"K\" value=\"2.73\"/>
       <P unit=\"pascal\" value=\"3e-18\"/>
       <D unit=\"g/cm3\" value=\"1e-25\"/>
       <atom unit=\"g/mole\" value=\"1.01\"/>
     </material>
</materials>

<solids>
     <box lunit=\"mm\" name=\"boxMother\" x=\"200000\" y=\"200000\" z=\"200000\"/>
</solids>

  <structure>

    <volume name=\"logicMother\">
      <materialref ref=\"Vacuum\"/>
      <solidref ref=\"boxMother\"/>

      <physvol>
      <file name=\"detector${opt_T}.gdml\"/>
      <positionref ref=\"detectorCenter\"/>
      <rotationref ref=\"rot\"/>
      </physvol>

    </volume>
  </structure>

  <setup name=\"Default\" version=\"1.0\">
    <world ref=\"logicMother\"/>
  </setup>
 
</gdml>";
close(def) or warn "close failed: $!";

##--------------------Write to matrices.xml file----------------------------------------##

open( def, ">", "matrices${opt_T}.xml" )
  or die "cannot open > matrices${opt_T}.xml: $!";
print def "<matrix name=\"Quartz_RINDEX\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $RefractiveIndex1[$o]";
    if ( $o == o ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"Quartz_ABSLENGTH\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $Absorption1[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"Air_RINDEX\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $RefractiveIndex2[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"Scnt_FAST\" coldim=\"2\" values=\"";
for $o ( 0 .. $#Scnt_PP ) {
    print def "$Scnt_PP[$o] $Scnt_FAST[$o]";
    if ( $o == $#Scnt_PP ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"Scnt_SLOW\" coldim=\"2\" values=\"";
for $o ( 0 .. $#Scnt_PP ) {
    print def "$Scnt_PP[$o] $Scnt_SLOW[$o]";
    if ( $o == $#Scnt_PP ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"AR_RINDEX\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $RefractiveIndexAR[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"CO2_RINDEX\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $RefractiveIndexCO2[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"CO2_ABSLENGTH\" coldim=\"2\" values=\"";
for $o ( 0 .. $#PhotonEC ) {
    print def "$PhotonEC[$o] $CO2_1atm_AbsLen[$o]";
    if ( $o == $#PhotonEC ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"N2_RINDEX\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $RefractiveIndexN2[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"Quartz_Surf_RINDEX\" coldim=\"2\" values=\"";
for $o ( 0 .. $#Ephoton ) {
    print def "$Ephoton[$o] $RefractiveIndex[$o]";
    if ( $o == $#Ephoton ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"Quartz_Surf_SPECLOBE\" coldim=\"2\" values=\"";
for $o ( 0 .. $#Ephoton ) {
    print def "$Ephoton[$o] $SpecularLobe[$o]";
    if ( $o == $#Ephoton ) { print def "\"/>"; }
    print def "\n";
}

print def "<matrix name=\"Quartz_Surf_SPECSPIKE\" coldim=\"2\" values=\"";
for $o ( 0 .. $#Ephoton ) {
    print def "$Ephoton[$o] $SpecularSpike[$o]";
    if ( $o == $#Ephoton ) { print def "\"/>"; }
    print def "\n";
}
print def "<matrix name=\"Quartz_Surf_BACKSCATTER\" coldim=\"2\" values=\"";
for $o ( 0 .. $#Ephoton ) {
    print def "$Ephoton[$o] $Backscatter[$o]";
    if ( $o == $#Ephoton ) { print def "\"/>"; }
    print def "\n";
}
print def "<matrix name=\"Aluminium_Surf_Reflectivity\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $Reflectivity3[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}
print def "<matrix name=\"Mylar_Surf_Reflectivity\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $Reflect_LG[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}
print def "<matrix name=\"Cathode_Surf_Reflectivity\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $Reflectivity4[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}
print def "<matrix name=\"Cathode_Surf_Efficiency\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $Efficiency4[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}
print def "<matrix name=\"Mylar_Surf_Reflectivity_Alt\" coldim=\"2\" values=\"";
for ( $o = $#PhotonEnergy ; $o >= 0 ; $o -= 1 ) {
    print def "$PhotonEnergy[$o] $MylarReflectivity[$o]";
    if ( $o == 0 ) { print def "\"/>"; }
    print def "\n";
}

##--------------------1x1 matrix properties--------------------------------------##
print def "
<matrix name=\"Air_Const_Scint\" coldim=\"1\" values=\"25./MeV\"/>";
print def "
<matrix name=\"Ar_Const_Scint\" coldim=\"1\" values=\"510./MeV\"/>";
print def "
<matrix name=\"CO2_Const_Scint\" coldim=\"1\" values=\"5./MeV\"/>";
print def "
<matrix name=\"N2_Const_Scint\" coldim=\"1\" values=\"140./MeV\"/>";

print def "
<matrix name=\"General_Const_RESOLUTION\" coldim=\"1\" values=\"2.0\"/>";
print def "
<matrix name=\"General_Const_FAST\" coldim=\"1\" values=\"1.*ns\"/>";
print def "
<matrix name=\"General_Const_SLOW\" coldim=\"1\" values=\"10.*ns\"/>";
print def "
<matrix name=\"General_Const_YIELDRATIO\" coldim=\"1\" values=\"1.0\"/>";

close(def) or warn "close failed: $!";

##-------------------------------------------------------------------------------##

##--------------------Start defining solids.-------------------------------------##

open( def, ">", "solids${opt_T}.xml" )
  or die "cannot open > solids${opt_T}.xml: $!";
print def "<solids>\n\n";

#---------------------Defining solid of mother volume.-------------------------------------------------------------------------------------#
{
    my $dxMabs;
    my $dxM2abs;
    my $dxMshift;
    $dxMabs   = abs($dxMext);
    $dxM2abs  = $dxM + 2 * $dxMabs;
    $dxMshift = ( $dxMext <=> 0 ) * ( $dxM + $dxMext ) / 2;

    print def
"<box lunit=\"mm\" name=\"boxMotherSolBase${opt_T}\" x=\"$dxM\" y=\"$dyM\" z=\"$dzM\"/>\n";
    print def
"<box lunit=\"mm\" name=\"boxMotherSolExt${opt_T}\" x=\"$dxMabs\" y=\"$dyM\" z=\"$dzM\"/>\n";

    print def "<union name =\"boxMotherSol${opt_T}\">
	<first ref=\"boxMotherSolBase${opt_T}\"/> 
	<second ref=\"boxMotherSolExt${opt_T}\"/> 
	<position unit=\"mm\" name=\"boxMotherPos${opt_T}\" x=\"$dxMshift\" y=\"0\" z=\"0\"\/>
</union>\n\n";

    print def
"<cone aunit=\"rad\" deltaphi=\"2*pi\" lunit=\"mm\" name=\"coneMotherSol${opt_T}\" rmax1=\"$drMinM\" rmax2=\"$drMinM\" rmin1=\"0\" rmin2=\"0\" startphi=\"0\" z=\"$dxM2abs\"/>\n";

    print def "<subtraction name =\"logicMotherSol${opt_T}\">
	<first ref=\"boxMotherSol${opt_T}\"/> 
	<second ref=\"coneMotherSol${opt_T}\"/> 
	<position unit=\"mm\" name=\"coneMotherPos${opt_T}\" x=\"0\" y=\"0\" z=\"0\"\/>
        <rotation unit=\"rad\" name=\"coneMotherRot${opt_T}\" x=\"0\" y=\"pi/2\" z=\"0\"/>
</subtraction>\n\n";
}

#------------------------------------------------------------------------------------------------------------------------------------------#

#-----------------------Defining solids of detector volume-----------------------------------------------------------------------------------#
for $j ( 0 .. $i - 1 ) {
    print def
"<box name=\"quartzRecSol_$index[$j]\" x=\"$dx[$j]\" y=\"$dy[$j]\" z=\"$dz[$j]\" lunit= \"mm\" />\n";

    print def "<xtru name = \"quartzCutSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"", $dx[$j] * ( 0.5 * tan( abs( $quartzCutAngle[$j] ) ) ),
      "\" y=\"", $dx[$j] * (0.5), "\" />
 <twoDimVertex x=\"", $dx[$j] * ( 0.5 * tan( abs( $quartzCutAngle[$j] ) ) ),
      "\" y=\"", $dx[$j] * (-0.5), "\" />
 <twoDimVertex x=\"", $dx[$j] * ( -0.5 * tan( abs( $quartzCutAngle[$j] ) ) ),
      "\" y=\"", $dx[$j] * (-0.5), "\" />
 <section zOrder=\"1\" zPosition=\"", $dy[$j] * (-0.5),
      "\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"", $dy[$j] * (0.5),
      "\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
</xtru>\n";

    print def "<union name=\"quartzSol_$index[$j]\">
    <first ref=\"quartzRecSol_$index[$j]\"/>
    <second ref=\"quartzCutSol_$index[$j]\"/>
    <position name=\"quartzCutSolPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",
      $dx[$j] * ( 0.5 * tan( abs( $quartzCutAngle[$j] ) ) ) + $dz[$j] * (0.5),
      "\"/>
    <rotation name=\"quartzCutSolRot_$index[$j]\" unit=\"rad\" x=\"pi/2\" y=\"0\" z=\"pi\"/> 
</union>\n";

    $angle1 = atan( abs( $dxLg[$j] - $dxPmt[$j] ) / $dzLg[$j] );
    $angle2 = atan( abs( $dyLg[$j] - $dyPmt[$j] ) / $dzLg[$j] );

#print def "<trd name = \"lgLogicSolOld_$index[$j]\" z=\"$dzLg[$j]\" y1=\"",$dyLg[$j]+2*$dtWall[$j]/(cos($angle2)),"\" x1=\"",$dxLg[$j]+2*$dtWall[$j]/(cos($angle1)),"\" y2=\"",$dyPmt[$j]+2*$dtWall[$j]/(cos($angle2)),"\" x2=\"",$dxPmt[$j]+2*$dtWall[$j]/(cos($angle1)),"\" lunit= \"mm\"/>\n";
    print def "<trap name = \"lgLogicSol1_$index[$j]\" z=\"",
      $dzLg[$j] + 1 * $dzLgExtra[$j], "\" theta=\"0.0\" phi=\"0.0\" y1=\"",
      $dyLg[$j] + 2 * $dtWall[$j] /  ( cos($angle2) ), "\" x1=\"",
      $dxLg[$j] + 2 * $dtWall[$j] /  ( cos($angle1) ), "\" x2=\"",
      $dxLg[$j] + 2 * $dtWall[$j] /  ( cos($angle1) ), "\" y2=\"",
      $dyPmt[$j] + 2 * $dtWall[$j] / ( cos($angle2) ), "\" x3=\"",
      $dxLg[$j] + 2 * $dtWall[$j] /  ( cos($angle1) ), "\" x4=\"",
      $dxLg[$j] + 2 * $dtWall[$j] /  ( cos($angle1) ),
      "\" alpha1=\"0.0\" alpha2=\"0*(", $lgTiltAngle[$j] + $ry[$j],
      ")\" aunit=\"rad\" lunit=\"mm\"/>\n";
    print def "<box name = \"lgLogicSol_sub1_$index[$j]\" z=\"",
      4 * $dzLgExtra[$j], "\" y=\"",
      1.5 * ( $dyPmt[$j] + 2 * $dtWall[$j] / ( cos($angle2) ) ), "\" x=\"",
      1.5 * ( $dxLg[$j] + 2 * $dtWall[$j] /  ( cos($angle1) ) ), "\"/>\n";
    print def "<box name = \"lgLogicSol_sub2_$index[$j]\" z=\"",
      2 * $dzLgExtra[$j], "\" y=\"",
      1.5 * ( $dyPmt[$j] + 2 * $dtWall[$j] / ( cos($angle2) ) ), "\" x=\"",
      1.5 * ( $dxLg[$j] + 2 * $dtWall[$j] /  ( cos($angle1) ) ), "\"/>\n";
    print def "<subtraction name =\"lgLogicSol_sub_$index[$j]\">
	<first ref=\"lgLogicSol_sub1_$index[$j]\"/> 
	<second ref=\"lgLogicSol_sub2_$index[$j]\"/> 
	<position unit=\"mm\" name=\"lgSolPos_sub1_$index[$j]\" x=\"0\" y=\"0\" z=\"",
      -1.0 * $dzLgExtra[$j], "\"\/>
    <rotation unit=\"rad\" name=\"lgSolRot_sub1_$index[$j]\" z=\"0\" y=\"0\" x=\"0\"/>
</subtraction>\n\n";
    print def "<subtraction name =\"lgLogicSol_$index[$j]\">
	<first ref=\"lgLogicSol1_$index[$j]\"/> 
	<second ref=\"lgLogicSol_sub_$index[$j]\"/> 
	<position unit=\"mm\" name=\"lgSolPos_sub_$index[$j]\" x=\"0\" y=\"0\" z=\"",
      0.5 * ( $dzLg[$j] - 1.0 * $dzLgExtra[$j] ), "\"\/>
    <rotation unit=\"rad\" name=\"lgSolRot_sub_$index[$j]\" z=\"0\" y=\"",
      $lgTiltAngle[$j] + $ry[$j], "\" x=\"0\"/>
</subtraction>\n\n";

    print def "<xtru name = \"refLogicSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",
      $dx[$j] *
      (0.5) +
      $dzRef[$j] *
      tan( $refTopOpeningAngle[$j] ) +
      ( ( $dtWall[$j] + $dtReflector[$j] ) /
          cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) ) *
      cos( $lgTiltAngle[$j] ), "\" y=\"",
      $dzRef[$j] * 0.5 +
      ( ( $dtWall[$j] + $dtReflector[$j] ) /
          cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) ) *
      sin( $lgTiltAngle[$j] ), "\" />
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) +
      $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
      ( $dxLg[$j] + $dtWall[$j] ) * cos( $lgTiltAngle[$j] ), "\" y=\"",
      $dzRef[$j] * (0.5) -
      ( $dxLg[$j] + $dtWall[$j] ) * sin( $lgTiltAngle[$j] ), "\" />
 <twoDimVertex x=\"", $dx[$j] * (-0.5) - $dtWall[$j] / cos( $lgTiltAngle[$j] ),
      "\" y=\"", $dzRef[$j] * (-0.5), "\" />
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) +
      ( $dtWall[$j] + $dtReflector[$j] ) / cos( $refTopOpeningAngle[$j] ),
      "\" y=\"", $dzRef[$j] * (-0.5), "\" />
 <section zOrder=\"1\" zPosition=\"", $dyLg[$j] * (-0.5) - $dtWall[$j],
      "\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"", $dyLg[$j] * (0.5) + $dtWall[$j],
      "\" xOffset=\"", 0, "\" yOffset=\"0\" scalingFactor=\"", 1, "\"/>
</xtru>\n";

    print def "<box name=\"pmtLogicSol_$index[$j]\" x=\"", $dxPmt[$j],
      "\" y=\"$dyPmt[$j]\" z=\"", $dzPmt[$j], "\" lunit= \"mm\" />\n";

    print def "<union name=\"TotalDetectorLogicSol1_$index[$j]\">
    <first ref=\"quartzRecSol_$index[$j]\"/>
    <second ref=\"refLogicSol_$index[$j]\"/>
    <position name=\"refLogicSolPos_$index[$j]\" unit=\"mm\" x=\"", 0,
      "\" y=\"0\" z=\"", 0.5 * $dz[$j] + 0.5 * $dzRef[$j], "\"/>
    <rotation name=\"refLogicSolRot_$index[$j]\" unit=\"rad\" x=\"pi/2\" y=\"",
      0, "\" z=\"0\"/> 
</union>\n";

    print def "<union name=\"TotalDetectorLogicSol2_$index[$j]\">
    <first ref=\"TotalDetectorLogicSol1_$index[$j]\"/>
    <second ref=\"lgLogicSol_$index[$j]\"/>
    <position name=\"lgLogicSolPos_$index[$j]\" unit=\"mm\" x=\"",
      0.5 * $dx[$j] +
      $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
      0.5 * $dxLg[$j] * cos( $lgTiltAngle[$j] ) -
      ( $dzLg[$j] + $dzLgExtra[$j] ) * 0.5 * sin( $lgTiltAngle[$j] ),
      "\" y=\"0\" z=\"",
      $dz[$j] * (0.5) +
      $dzRef[$j] -
      0.5 * $dxLg[$j] * sin( $lgTiltAngle[$j] ) +
      ( $dzLg[$j] + 1 * $dzLgExtra[$j] ) * 0.5 * cos( $lgTiltAngle[$j] ), "\"/>
    <rotation name=\"lgLogicSolRot_$index[$j]\" unit=\"rad\" x=\"0\" y=\"",
      $lgTiltAngle[$j] * (-1), "\" z=\"0\"/> 
</union>\n";

    print def "<union name=\"TotalDetectorLogicSol_$index[$j]\">
    <first ref=\"TotalDetectorLogicSol2_$index[$j]\"/>
    <second ref=\"pmtLogicSol_$index[$j]\"/>
      <position name=\"pmtLogicSolPos_$index[$j]\" unit=\"mm\" x=\"",
      ( $opt_I eq "" ) ? (
        0.5 * $dx[$j] +
        $dzRef[$j] *
        tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] *
        cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + $dzPmt[$j] * 0.5 ) *
        sin( $lgTiltAngle[$j] ) +
        cos( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        sin( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        0.5 * $dx[$j] +
        $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] * cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + $dzPmt[$j] * 0.5 ) * sin( $lgTiltAngle[$j] ),
      ), "\" y=\"0\" z=\"",
      ( $opt_I eq "" ) ? (
        $dz[$j] *
        (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] *
        sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + $dzPmt[$j] * 0.5 ) *
        cos( $lgTiltAngle[$j] ) +
        sin( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        cos( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        $dz[$j] * (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] * sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + $dzPmt[$j] * 0.5 ) * cos( $lgTiltAngle[$j] )
      ), "\"/>
      <rotation name=\"pmtLogicSolRot_$index[$j]\" unit=\"rad\" x=\"0\" y=\"",
      ( $opt_I eq "" ) ? (
        1 * $ry[$j]
      ) : (
        $lgTiltAngle[$j] * (-1)
      ), "\" z=\"0\"/>
</union>\n";

#print def "<trd name = \"lgSolOld_$index[$j]\" z=\"$dzLg[$j]\" y1=\"$dyLg[$j]\" x1=\"$dxLg[$j]\" y2=\"$dyPmt[$j]\" x2=\"$dxPmt[$j]\" lunit= \"mm\"/>\n";
    print def "<trap name = \"lgSol1_$index[$j]\" z=\"",
      $dzLg[$j] + 1 * $dzLgExtra[$j],
"\" theta=\"0.0\" phi=\"0.0\" y1=\"$dyLg[$j]\" x1=\"$dxLg[$j]\" x2=\"$dxLg[$j]\" y2=\"$dyPmt[$j]\" x3=\"$dxLg[$j]\" x4=\"$dxLg[$j]\" alpha1=\"0.0\" alpha2=\"0*(",
      $lgTiltAngle[$j] + $ry[$j], ")\" aunit=\"rad\" lunit=\"mm\"/>\n";
    print def "<box name = \"lgSol_sub1_$index[$j]\" z=\"", 4 * $dzLgExtra[$j],
      "\" y=\"", 1.5 * ( $dyPmt[$j] ), "\" x=\"", 1.5 * ( $dxLg[$j] ), "\"/>\n";
    print def "<box name = \"lgSol_sub2_$index[$j]\" z=\"", 2 * $dzLgExtra[$j],
      "\" y=\"", 1.5 * ( $dyPmt[$j] ), "\" x=\"", 1.5 * ( $dxLg[$j] ), "\"/>\n";
    print def "<subtraction name =\"lgSol_sub_$index[$j]\">
	<first ref=\"lgSol_sub1_$index[$j]\"/> 
	<second ref=\"lgSol_sub2_$index[$j]\"/> 
	<position unit=\"mm\" name=\"lgPos_sub1_$index[$j]\" x=\"0\" y=\"0\" z=\"",
      -1.0 * $dzLgExtra[$j], "\"\/>
    <rotation unit=\"rad\" name=\"lgRot_sub1_$index[$j]\" z=\"0\" y=\"0\" x=\"0\"/>
</subtraction>\n\n";
    print def "<subtraction name =\"lgSol_$index[$j]\">
	<first ref=\"lgSol1_$index[$j]\"/> 
	<second ref=\"lgSol_sub_$index[$j]\"/> 
	<position unit=\"mm\" name=\"lgPos_sub_$index[$j]\" x=\"0\" y=\"0\" z=\"",
      0.5 * ( $dzLg[$j] - 1.0 * $dzLgExtra[$j] ), "\"\/>
    <rotation unit=\"rad\" name=\"lgRot_sub_$index[$j]\" z=\"0\" y=\"",
      $lgTiltAngle[$j] + $ry[$j], "\" x=\"0\"/>
</subtraction>\n\n";

    print def "<subtraction name =\"lgSolSkin_$index[$j]\">
	<first ref=\"lgLogicSol_$index[$j]\"/> 
	<second ref=\"lgSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"lgSolPos_$index[$j]\" x=\"0\" y=\"0\" z=\"", 0,
      "\"\/>
    <rotation unit=\"rad\" name=\"lgSolRot_$index[$j]\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";

    print def "<xtru name = \"refSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) + $dzRef[$j] * tan( $refTopOpeningAngle[$j] ), "\" y=\"",
      $dzRef[$j] * 0.5, "\" />
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) +
      $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
      ( $dxLg[$j] ) * cos( $lgTiltAngle[$j] ), "\" y=\"",
      $dzRef[$j] * (0.5) - ( $dxLg[$j] ) * sin( $lgTiltAngle[$j] ), "\" />
 <twoDimVertex x=\"", $dx[$j] * (-0.5), "\" y=\"", $dzRef[$j] * (-0.5), "\" />
 <twoDimVertex x=\"", $dx[$j] * (0.5),  "\" y=\"", $dzRef[$j] * (-0.5), "\" />
 <section zOrder=\"1\" zPosition=\"", $dyLg[$j] * (-0.5),
      "\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"", $dyLg[$j] * (0.5), "\" xOffset=\"", 0,
      "\" yOffset=\"0\" scalingFactor=\"", 1, "\"/>
</xtru>\n";

    print def "<subtraction name =\"refSolSkin_$index[$j]\">
	<first ref=\"refLogicSol_$index[$j]\"/> 
	<second ref=\"refSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"refSolPos_$index[$j]\" x=\"0\" y=\"0\" z=\"", 0,
      "\"\/>
        <rotation unit=\"rad\" name=\"refSolRot_$index[$j]\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";

    print def "<subtraction name =\"refSol1_$index[$j]\">
	<first ref=\"refSol_$index[$j]\"/> 
	<second ref=\"quartzCutSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"quartzCutPos_$index[$j]\" x=\"0\" y=\"$dzRef[$j]*(-0.5)+$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j])))\" z=\"",
      0, "\"\/>
        <rotation unit=\"rad\" name=\"quartzCutRot_$index[$j]\" x=\"0\" y=\"pi\" z=\"0\"/>
</subtraction>\n\n";

    print def "<xtru name = \"reflectorSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) -
      0.05*$dzRef[$j]*sin($opt_t*pi/180.0)
      + ($opt_i+1.0)*0.1*$dzRef[$j] * tan( $refTopOpeningAngle[$j] ) +
      0.1*( $dtReflector[$j] / cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) )
      * cos( $lgTiltAngle[$j] ), "\" y=\"",
      (-0.4+0.1*$opt_i)*$dzRef[$j] +
      0.1*( $dtReflector[$j] / cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) )
      * sin( $lgTiltAngle[$j] ), "\" />
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) -
      0.05*$dzRef[$j]*sin($opt_t*pi/180.0)
      + ($opt_i+1.0)*0.1*$dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
      0.0*( $dtReflector[$j] / cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) )
      * cos( $lgTiltAngle[$j] ), "\" y=\"",
      (-0.4+0.1*$opt_i)*$dzRef[$j], "\" />
 <twoDimVertex x=\"", 
      $dx[$j] * (0.5) + 
      0.05*$dzRef[$j]*sin($opt_t*pi/180.0)
      +($opt_i)*0.1*$dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
      0.0*( $dtReflector[$j] / cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) )
      * cos( $lgTiltAngle[$j] ), "\" y=\"",
      (-0.5+0.1*$opt_i)*$dzRef[$j], "\" />
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) + 
      0.05*$dzRef[$j]*sin($opt_t*pi/180.0)
      +($opt_i)*0.1*$dzRef[$j] * tan( $refTopOpeningAngle[$j] ) +
      0.1*( $dtReflector[$j] / cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) )
      * cos( $lgTiltAngle[$j] ), "\" y=\"",
      (-0.5+0.1*$opt_i)*$dzRef[$j], "\" />
 <section zOrder=\"1\" zPosition=\"", (-0.5+0.1*$opt_j)*$dyLg[$j],
      "\" xOffset=\"", -0.05*sin($opt_p*pi/180.0)*$dyLg[$j],
      "\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"", (-0.4+0.1*$opt_j)*$dyLg[$j],
      "\" xOffset=\"", 0.05*sin($opt_p*pi/180.0)*$dyLg[$j],
      "\" yOffset=\"0\" scalingFactor=\"", 1, "\"/>
</xtru>\n";

    print def "<xtru name = \"reflectorSolXtru_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) +
      $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) +
      ( 20*$dtReflector[$j] / cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) )
      * cos( $lgTiltAngle[$j] ), "\" y=\"",
      $dzRef[$j] * 0.5 +
      ( $dtReflector[$j] / cos( $lgTiltAngle[$j] + $refTopOpeningAngle[$j] ) )
      * sin( $lgTiltAngle[$j] ), "\" />
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) + $dzRef[$j] * tan( $refTopOpeningAngle[$j] ), "\" y=\"",
      $dzRef[$j] * (0.5), "\" />
 <twoDimVertex x=\"", $dx[$j] * (0.5), "\" y=\"", $dzRef[$j] * (-0.5), "\" />
 <twoDimVertex x=\"",
      $dx[$j] * (0.5) + 20*$dtReflector[$j] / cos( $refTopOpeningAngle[$j] ),
      "\" y=\"", $dzRef[$j] * (-0.5), "\" />
 <section zOrder=\"1\" zPosition=\"", $dyLg[$j] * (-0.5),
      "\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"", $dyLg[$j] * (0.5), "\" xOffset=\"", 0,
      "\" yOffset=\"0\" scalingFactor=\"", 1, "\"/>
</xtru>\n";

    print def "<subtraction name =\"refSolSkin1_$index[$j]\">
	<first ref=\"refSolSkin_$index[$j]\"/> 
	<second ref=\"reflectorSolXtru_$index[$j]\"/> 
	<position name=\"reflectorSolPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",
      0, "\"/>
	<rotation name=\"reflectorSolRot_$index[$j]\" unit=\"rad\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";

    print def
"<cone name = \"pmtFullSol_$index[$j]\" rmin1=\"0\" rmax1=\"$drPmt[$j]\" rmin2=\"0\" rmax2=\"$drPmt[$j]\" z=\"$dzPmt[$j]\"
startphi=\"0\" deltaphi=\"2*pi\" aunit=\"rad\" lunit= \"mm\" />\n";
    print def "<subtraction name =\"pmtSkinSol_$index[$j]\">
	<first ref=\"pmtLogicSol_$index[$j]\"/> 
	<second ref=\"pmtFullSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"pmtSolPos_$index[$j]\" x=\"0\" y=\"0\" z=\"", 0,
      "\"\/>
        <rotation unit=\"rad\" name=\"pmtSolRot_$index[$j]\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";

    print def
"<cone name = \"pmtCathodeSol_$index[$j]\" rmin1=\"0\" rmax1=\"$drPmt[$j]\" rmin2=\"0\" rmax2=\"$drPmt[$j]\" z=\"",
      $dzPmt[$j] / 100.0, "\"
startphi=\"0\" deltaphi=\"2*pi\" aunit=\"rad\" lunit= \"mm\" />\n";
    print def
"<cone name = \"pmtCathodeSol_sub_$index[$j]\" rmin1=\"0\" rmax1=\"1.01*$drPmt[$j]\" rmin2=\"0\" rmax2=\"1.01*$drPmt[$j]\" z=\"",
      1.01 * $dzPmt[$j] / 100.0, "\"
startphi=\"0\" deltaphi=\"2*pi\" aunit=\"rad\" lunit= \"mm\" />\n";
    print def "<subtraction name =\"pmtSol_$index[$j]\">
	<first ref=\"pmtFullSol_$index[$j]\"/> 
	<second ref=\"pmtCathodeSol_sub_$index[$j]\"/> 
	<position unit=\"mm\" name=\"pmtCathodeSolPos_$index[$j]\" x=\"0\" y=\"0\" z=\"",
      -1.0 * ( $dzPmt[$j] / 2.0 ) + ( $dzPmt[$j] / 200.0 ), "\"/>
    <rotation unit=\"rad\" name=\"pmtCathodeSolRot_$index[$j]\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";
}

#-----------------------------------------------FIXME Placeholders from Brad's code-----------------------------------------------------------------------------------#
print def "
        <opticalsurface name=\"Quartz\" model=\"glisur\" finish=\"ground\" type=\"dielectric_dielectric\" value=\".98\">
			<property name=\"RINDEX\" ref=\"Quartz_Surf_RINDEX\"/>
			<property name=\"SPECULARLOBECONSTANT\" ref=\"Quartz_Surf_SPECLOBE\"/>
			<property name=\"SPECULARSPIKECONSTANT\" ref=\"Quartz_Surf_SPECSPIKE\"/> 
			<property name=\"BACKSCATTERCONSTANT\" ref=\"Quartz_Surf_BACKSCATTER\"/> 
		</opticalsurface>";

print def "
        <opticalsurface name=\"Aluminium\" model=\"glisur\" finish=\"polishedlumirrorair\" type=\"dielectric_metal\" value=\"1.0\">
	    	<property name=\"REFLECTIVITY\" ref=\"Aluminium_Surf_Reflectivity\"/>
        </opticalsurface>";
print def "
        <opticalsurface name=\"Mylar\" model=\"glisur\" finish=\"polishedlumirrorair\" type=\"dielectric_metal\" value=\"1.0\">
			<property name=\"REFLECTIVITY\" ref=\"Mylar_Surf_Reflectivity\"/>
        </opticalsurface>";
print def "
        <opticalsurface name=\"Cathode\" model=\"glisur\" finish=\"polishedlumirrorair\" type=\"dielectric_metal\" value=\"1.0\">
			<property name=\"REFLECTIVITY\" ref=\"Cathode_Surf_Reflectivity\"/>
			<property name=\"EFFICIENCY\" ref=\"Cathode_Surf_Efficiency\"/>
        </opticalsurface>";

#----------------------------------------------------------------------------------------------------------------------------------#

print def "\n</solids>";
close(def) or warn "close failed: $!";
##-----------------------------------------------End Defining solids.----------------------------------------------------------------------------------##

##--------------------------------------------------------------Start Structure.------------------------------------------------------------------------##
open( def, ">", "detector${opt_T}.gdml" )
  or die "cannot open > detector${opt_T}.gdml: $!";
print def "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n
<!DOCTYPE gdml [
	<!ENTITY materials SYSTEM \"materialsOptical.xml\"> 
	<!ENTITY solids${opt_T} SYSTEM \"solids${opt_T}.xml\"> 
	<!ENTITY matrices${opt_T} SYSTEM \"matrices${opt_T}.xml\">
]> \n
<gdml xmlns:gdml=\"http://cern.ch/2001/Schemas/GDML\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"http://service-spi.web.cern.ch/service-spi/app/releases/GDML/schema/gdml.xsd\">\n

<define>
&matrices${opt_T};
</define>
&materials; 
&solids${opt_T};\n
<structure>\n";

for $j ( 0 .. $i - 1 ) {

    print def "
<volume name=\"quartzRecVol_$index[$j]\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"quartzSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"red\"/> 
         <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"boundaryhits\"/> 
         <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 1, "\"/>  
</volume>\n";

    print def
"<skinsurface name=\"quartzRecVol_$index[$j]_skin\" surfaceproperty=\"Quartz\" >
         <volumeref ref=\"quartzRecVol_$index[$j]\"/>
</skinsurface>\n ";

    print def "
<volume name=\"refVol_$index[$j]\">
         <materialref ref=\"QsimAir\"/>
         <solidref ref=\"refSol1_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"green\"/> 
         <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"boundaryhits\"/> 
         <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 2, "\"/>  
</volume>\n";

    print def "
<volume name=\"refVolSkin_$index[$j]\">
         <materialref ref=\"AlMylar\"/>
         <solidref ref=\"refSolSkin1_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"brown\"/> 
         <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"opticalphoton\"/> 
         <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 3, "\"/>  
</volume>\n";

    print def "
<skinsurface name=\"refVolSkin_$index[$j]_skin\" surfaceproperty=\"Mylar\" >
         <volumeref ref=\"refVolSkin_$index[$j]\"/>
</skinsurface>\n";

    print def "
<volume name=\"reflectorVol_$index[$j]\">
         <materialref ref=\"AlMylar\"/>
         <solidref ref=\"reflectorSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"red\"/> 
 	     <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"opticalphoton\"/> 
	     <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 4, "\"/>  
</volume>\n";

    print def "
<skinsurface name=\"reflectorVol_$index[$j]_skin\" surfaceproperty=\"Aluminium\" >
         <volumeref ref=\"reflectorVol_$index[$j]\"/>
</skinsurface>\n ";

    print def "
<volume name=\"lgVol_$index[$j]\">
         <materialref ref=\"QsimAir\"/>
         <solidref ref=\"lgSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"blue\"/> 
         <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"boundaryhits\"/> 
         <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 6, "\"/>  
</volume>\n";

    print def "
<volume name=\"lgVolSkin_$index[$j]\">
         <materialref ref=\"AlMylar\"/>
         <solidref ref=\"lgSolSkin_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"brown\"/> 
 	     <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"opticalphoton\"/> 
	     <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 5, "\"/>  
</volume>\n";

    print def "
<skinsurface name=\"lgVolSkin_$index[$j]_skin\" surfaceproperty=\"Mylar\" >
         <volumeref ref=\"lgVolSkin_$index[$j]\"/>
</skinsurface>\n ";

    print def "
<volume name=\"pmtVol_$index[$j]\">
         <materialref ref=\"Aluminium\"/>
         <solidref ref=\"pmtSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"red\"/> 
 	     <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"lowenergyneutral\"/> 
	     <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 7, "\"/>  
</volume>\n";

    print def "
<!--
<skinsurface name=\"pmtVol_$index[$j]_skin\" surfaceproperty=\"Aluminium\" >
         <volumeref ref=\"pmtVol_$index[$j]\"/>
</skinsurface>
-->\n ";

    print def "
<volume name=\"pmtCathodeVol_$index[$j]\">
         <materialref ref=\"Photocathode\"/>
         <solidref ref=\"pmtCathodeSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"green\"/> 
         <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
         <auxiliary auxtype=\"DetType\" auxvalue=\"opticalphoton\"/>
         <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 0, "\"/>
</volume>\n";

    print def "
<skinsurface name=\"pmtCathodeVol_$index[$j]_skin\" surfaceproperty=\"Cathode\" >
         <volumeref ref=\"pmtCathodeVol_$index[$j]\"/>
</skinsurface>\n ";

    print def "
<volume name=\"pmtSkinVol_$index[$j]\">
         <materialref ref=\"Aluminium\"/>
         <solidref ref=\"pmtSkinSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"grey\"/> 
</volume>\n";

    print def "
<!--
<skinsurface name=\"pmtSkinVol_$index[$j]_skin\" surfaceproperty=\"Aluminium\" >
         <volumeref ref=\"pmtSkinVol_$index[$j]\"/>
</skinsurface>
-->\n ";

    print def "
<volume name=\"TotalDetectorVol_$index[$j]\">
    <materialref ref=\"QsimAir\"/>
    <solidref ref=\"TotalDetectorLogicSol_$index[$j]\"/> 
    <physvol name=\"quartzRec_$index[$j]\">
         <volumeref ref=\"quartzRecVol_$index[$j]\"/>
		 <position name=\"quartzRecPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"0\"/>
		 <rotation name=\"quartzRecRot_$index[$j]\" unit=\"rad\" x=\"", 0,
      "\" y=\"0\" z=\"0\"/>
    </physvol> \n

    <!--
    <physvol name=\"ref_$index[$j]\">
		 <volumeref ref=\"refVol_$index[$j]\"/>
		 <position name=\"refPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",
      $dz[$j] * (0.5) + $dzRef[$j] * (0.5), "\"/>
		 <rotation name=\"refRot_$index[$j]\" unit=\"rad\" x=\"-pi/2\" y=\"0\" z=\"0\"/>
    </physvol>
    --> \n
         <physvol name=\"refSkin_$index[$j]\">
		 <volumeref ref=\"refVolSkin_$index[$j]\"/>
		 <position name=\"refSkinPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",
      $dz[$j] * (0.5) + $dzRef[$j] * (0.5), "\"/>
		 <rotation name=\"refSkinRot_$index[$j]\" unit=\"rad\" x=\"-pi/2\" y=\"0\" z=\"0\"/>
    </physvol> \n
         <physvol name=\"reflector_$index[$j]\">
		 <volumeref ref=\"reflectorVol_$index[$j]\"/>
		 <position name=\"reflectorPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",
      $dz[$j] * (0.5) + $dzRef[$j] * (0.5), "\"/>
		 <rotation name=\"reflectorRot_$index[$j]\" unit=\"rad\" x=\"-pi/2\" y=\"0\" z=\"0\"/>
    </physvol> \n

    <!--
    <physvol name=\"lg_$index[$j]\">
	 	<volumeref ref=\"lgVol_$index[$j]\"/>
	 	<position name=\"lgPos_$index[$j]\" unit=\"mm\" x=\"",
      0.5 * $dx[$j] +
      $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
      0.5 * $dxLg[$j] * cos( $lgTiltAngle[$j] ) -
      ( $dzLg[$j] + $dzLgExtra[$j] ) * 0.5 * sin( $lgTiltAngle[$j] ),
      "\" y=\"0\" z=\"",
      $dz[$j] * (0.5) +
      $dzRef[$j] -
      0.5 * $dxLg[$j] * sin( $lgTiltAngle[$j] ) +
      ( $dzLg[$j] + $dzLgExtra[$j] ) * 0.5 * cos( $lgTiltAngle[$j] ), "\"/>
		<rotation name=\"lgRot_$index[$j]\" unit=\"rad\" x=\"", 0, "\" y=\"",
      $lgTiltAngle[$j], "\" z=\"", 0, "\"/>
    </physvol>
    --> \n
    <physvol name=\"lgSkin_$index[$j]\">
	 	<volumeref ref=\"lgVolSkin_$index[$j]\"/>
		<position name=\"lgSkinPos_$index[$j]\" unit=\"mm\" x=\"",
      0.5 * $dx[$j] +
      $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
      0.5 * $dxLg[$j] * cos( $lgTiltAngle[$j] ) -
      ( $dzLg[$j] + $dzLgExtra[$j] ) * 0.5 * sin( $lgTiltAngle[$j] ),
      "\" y=\"0\" z=\"",
      $dz[$j] * (0.5) +
      $dzRef[$j] -
      0.5 * $dxLg[$j] * sin( $lgTiltAngle[$j] ) +
      ( $dzLg[$j] + $dzLgExtra[$j] ) * 0.5 * cos( $lgTiltAngle[$j] ), "\"/>
		<rotation name=\"lgSkinRot_$index[$j]\" unit=\"rad\" x=\"", 0, "\" y=\"",
      $lgTiltAngle[$j], "\" z=\"", 0, "\"/>
    </physvol> \n

    <physvol name=\"pmt_$index[$j]\">
      <volumeref ref=\"pmtVol_$index[$j]\"/>
      <position name=\"pmtPos_$index[$j]\" unit=\"mm\" x=\"",
      ($opt_I eq "") ? (
        0.5 * $dx[$j] +
        $dzRef[$j] *
        tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] *
        cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + 0.5 * ( $dzPmt[$j] + 1 * $dzPmt[$j] / 100 ) ) *
        sin( $lgTiltAngle[$j] ) +
        cos( $lgTiltAngle[$j] ) * 0.5 *
        ( $dzPmt[$j] + 1 * $dzPmt[$j] / 100 ) *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        sin( $lgTiltAngle[$j] ) * 0.5 *
        ( $dzPmt[$j] + 1 * $dzPmt[$j] / 100 ) *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        0.5 * $dx[$j] +
        $dzRef[$j] *
        tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] *
        cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + 0.5 * ( $dzPmt[$j] + $dzPmt[$j] / 50 ) ) *
        sin( $lgTiltAngle[$j] )
      ), "\" y=\"0\" z=\"",
      ( $opt_I eq "") ? (
        $dz[$j] *
        (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] *
        sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + 0.5 * ( $dzPmt[$j] + 1 * $dzPmt[$j] / 100 ) ) *
        cos( $lgTiltAngle[$j] ) +
        sin( $lgTiltAngle[$j] ) * 0.5 *
        ( $dzPmt[$j] + 1 * $dzPmt[$j] / 100 ) *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        cos( $lgTiltAngle[$j] ) * 0.5 *
        ( $dzPmt[$j] + 1 * $dzPmt[$j] / 100 ) *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        $dz[$j] *
        (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] *
        sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + 0.5 * ( $dzPmt[$j] + $dzPmt[$j] / 50 ) ) *
        cos( $lgTiltAngle[$j] )
      ), "\"/>
		<rotation name=\"pmtRot_$index[$j]\" unit=\"rad\" x=\"", 0, "\" y=\"",
      ( $opt_I eq "" ) ? (
        -1 * $ry[$j]
      ) : (
        $lgTiltAngle[$j]
      ), "\" z=\"", 0, "\"/>
    </physvol> \n
    <physvol name=\"pmtCathode_$index[$j]\">
	    <volumeref ref=\"pmtCathodeVol_$index[$j]\"/>
		<position name=\"pmtCathodePos_$index[$j]\" unit=\"mm\" x=\"",
      ( $opt_I eq "" ) ? (
        0.5 * $dx[$j] +
        $dzRef[$j] *
        tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] *
        cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] / 100.0 ) *
        sin( $lgTiltAngle[$j] ) +
        cos( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] / 100.0 *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        sin( $lgTiltAngle[$j] ) * 0.5 *
        ( $dzPmt[$j] / 100.0 ) *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        0.5 * $dx[$j] +
        $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] * cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] / 100.0 ) * sin( $lgTiltAngle[$j] )
      ), "\" y=\"0\" z=\"",
      ( $opt_I eq "" ) ? (
        $dz[$j] *
        (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] *
        sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] / 100.0 ) *
        cos( $lgTiltAngle[$j] ) +
        sin( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] / 100.0 *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        cos( $lgTiltAngle[$j] ) * 0.5 *
        ( $dzPmt[$j] / 100.0 ) *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        $dz[$j] * (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] * sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] / 100.0 ) * cos( $lgTiltAngle[$j] )      ), "\"/>
      <rotation name=\"pmtCathodeRot_$index[$j]\" unit=\"rad\" x=\"", 0, "\" y=\"",
      ( $opt_I eq "" ) ? (
        -1 * $ry[$j]
      ) : (
        $lgTiltAngle[$j]
      ), "\" z=\"", 0, "\"/>
    </physvol> \n
    <physvol name=\"pmtSkin_$index[$j]\">
		<volumeref ref=\"pmtSkinVol_$index[$j]\"/>
		<position name=\"pmtSkinPos_$index[$j]\" unit=\"mm\" x=\"",
      ( $opt_I eq "" ) ? (
        0.5 * $dx[$j] +
        $dzRef[$j] *
        tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] *
        cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] ) *
        sin( $lgTiltAngle[$j] ) +
        cos( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        sin( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        0.5 * $dx[$j] +
        $dzRef[$j] * tan( $refTopOpeningAngle[$j] ) -
        0.5 * $dxLg[$j] * cos( $lgTiltAngle[$j] ) -
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] ) * sin( $lgTiltAngle[$j] ),
      )
      , "\" y=\"0\" z=\"",
      ( $opt_I eq "" ) ? (
        $dz[$j] *
        (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] *
        sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] ) *
        cos( $lgTiltAngle[$j] ) +
        sin( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        sin( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) -
        cos( $lgTiltAngle[$j] ) * 0.5 *
        $dzPmt[$j] *
        ( 1 - cos( 1 * $lgTiltAngle[$j] + 1 * $ry[$j] ) )
      ) : (
        $dz[$j] * (0.5) +
        $dzRef[$j] -
        0.5 * $dxLg[$j] * sin( $lgTiltAngle[$j] ) +
        ( $dzLg[$j] + 0.5 * $dzPmt[$j] ) * cos( $lgTiltAngle[$j] )
      )
      , "\"/>
      <rotation name=\"pmtSkinRot_$index[$j]\" unit=\"rad\" x=\"", 0, "\" y=\"",
      ( $opt_I eq "" ) ? (
        -1 * $ry[$j]
      ) : (
        $lgTiltAngle[$j]
      ), "\" z=\"", 0, "\"/>
    </physvol> \n  
</volume>\n";

}
##if ($opt_L != "")
#{
#    for $j(0..$i-1){
#        $x[$j] = 0.0;
#        $y[$j] = 0.0;
#        $z[$j] = 0.0;
#    }
#}

print def "
<volume name=\"logicMotherVol${opt_T}\"> 
	<materialref ref=\"QsimAir\"/>
	<solidref ref=\"logicMotherSol${opt_T}\"/>\n";
for $j ( 0 .. $i - 1 ) {
    print def "
    <physvol name=\"detector_$index[$j]\">
	    <volumeref ref=\"TotalDetectorVol_$index[$j]\"/>
      <!-- Easy origin, just uncomment these to put the quartz center at the origin
      <position name=\"detectorPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"0\"/>
      <rotation name=\"detectorRot_$index[$j]\" unit=\"rad\" x=\"0\" y=\"0\" z=\"0\"/>
      -->
	    <position name=\"detectorPos_$index[$j]\" unit=\"mm\" x=\"$x[$j]\" y=\"$y[$j]\" z=\"$z[$j]\"/>
    	<rotation name=\"detectorRot_$index[$j]\" unit=\"rad\" x=\"", $rx[$j],
      "\" y=\"$ry[$j]\" z=\"$rz[$j]\"/>
    </physvol> \n";
}
print def "
</volume>";

print def "
\n</structure>\n\n";

##-----------------------------------------End structure.--------------------------------------------------------------------------##
print def "
<setup name=\"logicMother${opt_T}\" version=\"1.0\">
	<world ref=\"logicMotherVol${opt_T}\"/>
</setup>\n
</gdml>";

close(def) or warn "close failed: $!";


##-------------------------------------------------------------------------------##

##--------------------Parallel sub-volume for flat-main detecto------------------##

open( def, ">", "flat_segmented_detector${opt_T}.gdml" )
  or die "cannot open > flat_segmented_detector${opt_T}.gdml: $!";
print def "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n
<gdml xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" 
      xsi:noNamespaceSchemaLocation=\"http://service-spi.web.cern.ch/service-spi/app/releases/GDML/schema/gdml.xsd\">\n
<solids>
";

$parallelDetPlaneThickness=1.0;
for $j ( 0 .. $i - 1 ) {
    $fullLength[$j]=$parallelPmtRStart[$j]-$parallelQuartzRCenter[$j]+0.5*$parallelQuartzRExtent[$j]+$dzPmt[$j];
    print def "
    <box name = \"quartzLogicParallel_$index[$j]\" x=\"$parallelQuartzRExtent[$j]\" y=\"$dy[$j]\" z=\"$parallelDetPlaneThickness\"/>
    <box name = \"refLogicParallel_$index[$j]\" x=\"$parallelReflectorRExtent[$j]\" y=\"$dy[$j]\" z=\"$parallelDetPlaneThickness\"/>
    <trap name = \"lgLogicParallel_$index[$j]\" z=\"",($parallelPmtRStart[$j]-$parallelQuartzRCenter[$j]-0.5*$parallelQuartzRExtent[$j]-$parallelReflectorRExtent[$j]),"\" theta=\"0.0\" phi=\"0.0\" y1=\"$dy[$j]\" x1=\"$parallelDetPlaneThickness\" x2=\"$parallelDetPlaneThickness\" y2=\"",(2.0*$drPmt[$j]),"\" x3=\"$parallelDetPlaneThickness\" x4=\"$parallelDetPlaneThickness\" alpha1=\"0.0\" alpha2=\"0.0\" aunit=\"rad\" lunit=\"mm\"/>
    <box name = \"pmtLogicParallel_$index[$j]\" x=\"$dzPmt[$j]\" y=\"",(2.0*$drPmt[$j]),"\" z=\"$parallelDetPlaneThickness\"/>
    <box lunit=\"mm\" name=\"flat_parallel_solid_$index[$j]\" z=\"",$fullLength[$j]+0.1,"\" y=\"",$dy[$j]+2*$dtWall[$j]+0.1,"\" x=\"",$parallelDetPlaneThickness+0.1,"\"/>\n";
}
print def "
<!-- Box to hold the detector array inside of -->

<box lunit=\"mm\" name=\"flat_parallel_solid2\" x=\"2010\" y=\"3010\" z=\"3010\"/>

</solids>

<structure>

";

for $j ( 0 .. $i - 1 ) {

    print def "
  <volume name=\"quartzVolParallel_$index[$j]\">
    <materialref ref=\"G4_Galactic\"/>
    <solidref ref=\"quartzLogicParallel_$index[$j]\"/> 
    <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
    <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 1, "\"/>  
  </volume>\n";

  print def "
  <volume name=\"reflectorVolParallel_$index[$j]\">
    <materialref ref=\"G4_Galactic\"/>
    <solidref ref=\"refLogicParallel_$index[$j]\"/> 
    <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
    <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 4, "\"/>  
  </volume>\n";

  print def "
  <volume name=\"lgVolSkinParallel_$index[$j]\">
    <materialref ref=\"G4_Galactic\"/>
    <solidref ref=\"lgLogicParallel_$index[$j]\"/> 
    <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
    <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 5, "\"/>  
  </volume>\n";
  print def "
  <volume name=\"pmtSkinVolParallel_$index[$j]\">
    <materialref ref=\"G4_Galactic\"/>
    <solidref ref=\"pmtLogicParallel_$index[$j]\"/> 
    <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
    <auxiliary auxtype=\"DetNo\" auxvalue=\"", $index[$j] + 7, "\"/>
  </volume>\n";

}



for $j ( 0 .. $i - 1 ) {
    print def "
  <volume name=\"Flat_Segmented_ParallelWorld_logical_$index[$j]\">
    <materialref ref=\"G4_Galactic\"/>
    <solidref ref=\"flat_parallel_solid_$index[$j]\"/>
      ";
    print def "
    <physvol name=\"quartzVolParallel_phys_$index[$j]\">
      <volumeref ref=\"quartzVolParallel_$index[$j]\"/>
      <position name=\"quartzVolParallelPos_$index[$j]\" unit=\"mm\" x=\"",0.0*$x[$j],"\" y=\"0\" z=\"",0.0*$parallelQuartzRCenter[$j]+$parallelQuartzRExtent[$j]/2-$fullLength[$j]/2,"\"/>
      <rotation name=\"quartzVolParallelRot_$index[$j]\" unit=\"rad\" x=\"0.0\" y=\"pi/2\" z=\"$rz[$j]\"/>
    </physvol> \n";
    print def "
    <physvol name=\"reflectorVolParallel_phys_$index[$j]\">
      <volumeref ref=\"reflectorVolParallel_$index[$j]\"/>
      <position name=\"reflectorVolParallelPos_$index[$j]\" unit=\"mm\" x=\"",0.0*$x[$j],"\" y=\"0\" z=\"",(0.0*$parallelQuartzRCenter[$j]+0.5*$parallelQuartzRExtent[$j]+0.5*$parallelReflectorRExtent[$j])+$parallelQuartzRExtent[$j]/2-$fullLength[$j]/2,"\"/>
      <rotation name=\"reflectorVolParallelRot_$index[$j]\" unit=\"rad\" x=\"0.0\" y=\"pi/2\" z=\"$rz[$j]\"/>
    </physvol> \n";
    print def "
    <physvol name=\"lgVolSkinParallel_phys_$index[$j]\">
      <volumeref ref=\"lgVolSkinParallel_$index[$j]\"/>
      <position name=\"lgVolSkinParallelPos_$index[$j]\" unit=\"mm\" x=\"",0.0*$x[$j],"\" y=\"0\" z=\"",(0.5*(-1.0*$parallelQuartzRCenter[$j]+0.5*$parallelQuartzRExtent[$j]+$parallelReflectorRExtent[$j]+$parallelPmtRStart[$j]))+$parallelQuartzRExtent[$j]/2-$fullLength[$j]/2,"\"/>
      <rotation name=\"lgVolSkinParallelRot_$index[$j]\" unit=\"rad\" x=\"0.0\" y=\"0.0\" z=\"$rz[$j]\"/>
    </physvol> \n";
    print def "
    <physvol name=\"pmtSkinVolParallel_phys_$index[$j]\">
      <volumeref ref=\"pmtSkinVolParallel_$index[$j]\"/>
      <position name=\"pmtSkinVolParallelPos_$index[$j]\" unit=\"mm\" x=\"",0.0*$x[$j],"\" y=\"0\" z=\"",(-1.0*$parallelQuartzRCenter[$j]+$parallelPmtRStart[$j]+0.5*$dzPmt[$j])+$parallelQuartzRExtent[$j]/2-$fullLength[$j]/2,"\"/>
      <rotation name=\"pmtSkinVolParallelRot_$index[$j]\" unit=\"rad\" x=\"0.0\" y=\"pi/2\" z=\"$rz[$j]\"/>
    </physvol>
  </volume>\n";
}
    print def"
  <volume name=\"Flat_Segmented_ParallelWorld_physical\">
    <materialref ref=\"G4_Galactic\"/>
    <solidref ref=\"flat_parallel_solid2\"/>
    ";
for $j ( 0 .. $i - 1 ) {
    print def"
    <physvol name=\"Flat_Segmented_ParallelWorld_physical_$index[$j]\">
      <volumeref ref=\"Flat_Segmented_ParallelWorld_logical_$index[$j]\"/>
	    <position name=\"Flat_DetectorPos_$index[$j]\" unit=\"mm\" x=\"$x[$j]\" y=\"$y[$j]\" z=\"",$z[$j]+$fullLength[$j]/2-$parallelQuartzRExtent[$j]/2,"\"/>
    	<rotation name=\"Flat_DetectorRot_$index[$j]\" unit=\"rad\" x=\"$rx[$j]\" y=\"0.0*$ry[$j]\" z=\"$rz[$j]\"/>
    </physvol>
    ";
  }
    print def"
  </volume>
    
</structure>

<setup name=\"Default\" version=\"1.0\">
  <world ref=\"Flat_Segmented_ParallelWorld_physical\"/>
</setup>

</gdml>";


close(def) or warn "close failed: $!";



sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s }
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s }
sub trim  { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s }

=pod

=cut
