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
use vars qw($opt_M $opt_D $opt_T $data $line @fields $dxM $dyM $dzM $drMinM $dxMext @index @x @y @z @dx @dy @dz @rx @ry @rz @quartzCutAngle @refTopOpeningAngle @dzRef @dxLg @dyLg @dzLg  @lgTiltAngle @dxPmt @dyPmt @dzPmt @drPmt @dtWall @dtReflector $i $j $k $angle1 $angle2);
##----------------------------------------------------------------------------------##

##------------------Get the option flags.------------------------------------------##
getopts('M:D:T:');

if ($#ARGV > -1){
    print STDERR "Unknown arguments specified: @ARGV\nExiting.\n";
    exit;
}
##----------------------------------------------------------------------------------##

##------------------Start Reading CSV file containing parameter values for mother volume.-------------##
open($data, '<', $opt_M);               # Open csv file.
$i=0;
while($line= <$data>){                  # Read each line till the end of the file.
if ($line =~ /^\s*$/) {    		# Check for empty lines.
    print "String contains 0 or more white-space character and nothing else.\n";
} else {
chomp $line;
@fields = split(",", $line);            # Split the line into fields.
$dxM=trim($fields[0]);                  # Get rid of initial and trailing white spaces.
$dyM=trim($fields[1]);
$dzM=trim($fields[2]);
$drMinM=trim($fields[3]);
$dxMext=trim($fields[4]);
$i=$i+1;
}
}
close $data;
##----------------------------------------------------------------------------------------------------##


##------------------Start Reading CSV file containing parameter values for detectors inside mother volume.-------------##
open($data, '<', $opt_D);               # Open csv file.
$i=0;
while($line= <$data>){                  # Read each line till the end of the file.
if ($line =~ /^\s*$/) {    		# Check for empty lines.
    print "String contains 0 or more white-space character and nothing else.\n";
} else
{
chomp $line;
@fields = split(",", $line);            # Split the line into fields.
$index[$i]=trim($fields[0]);            # Get rid of initial and trailing white spaces.
$x[$i]=trim($fields[1]);
$y[$i]=trim($fields[2]);
$z[$i]=trim($fields[3]);
$dx[$i]=trim($fields[4]);
$dy[$i]=trim($fields[5]);
$dz[$i]=trim($fields[6]);
$rx[$i]=trim($fields[7]);
$ry[$i]=trim($fields[8]);
$rz[$i]=trim($fields[9]);
$quartzCutAngle[$i]=trim($fields[10]);
$refTopOpeningAngle[$i]=trim($fields[11]);
$dzRef[$i]=trim($fields[12]);
$dxLg[$i]=trim($fields[13]);
$dyLg[$i]=trim($fields[14]);
$dzLg[$i]=trim($fields[15]);
$lgTiltAngle[$i]=trim($fields[16]);
$dxPmt[$i]=trim($fields[17]); 		
$dyPmt[$i]= trim($fields[18]);
$dzPmt[$i]= trim($fields[19]);
$drPmt[$i]= trim($fields[20]);
$dtWall[$i]= trim($fields[21]); 
$dtReflector[$i]= trim($fields[22]); 
$i=$i+1;
}
}
close $data;
##-------------------------------------------------------------------------------##


##--------------------Start defining solids.-------------------------------------## 

open(def, ">", "solids${opt_T}.xml") or die "cannot open > solids${opt_T}.xml: $!";
print def "<solids>\n\n";

#---------------------Defining solid of mother volume.-------------------------------------------------------------------------------------# 
{ my $dxMabs; my $dxM2abs; my $dxMshift;
$dxMabs = abs($dxMext);
$dxM2abs = $dxM+2*$dxMabs;
$dxMshift = ($dxMext<=>0)*($dxM+$dxMext)/2;

print def "<box lunit=\"mm\" name=\"boxMotherSolBase${opt_T}\" x=\"$dxM\" y=\"$dyM\" z=\"$dzM\"/>\n";
print def "<box lunit=\"mm\" name=\"boxMotherSolExt${opt_T}\" x=\"$dxMabs\" y=\"$dyM\" z=\"$dzM\"/>\n";

print def "<union name =\"boxMotherSol${opt_T}\">
	<first ref=\"boxMotherSolBase${opt_T}\"/> 
	<second ref=\"boxMotherSolExt${opt_T}\"/> 
	<position unit=\"mm\" name=\"boxMotherPos${opt_T}\" x=\"$dxMshift\" y=\"0\" z=\"0\"\/>
</union>\n\n";

print def "<cone aunit=\"rad\" deltaphi=\"2*PI\" lunit=\"mm\" name=\"coneMotherSol${opt_T}\" rmax1=\"$drMinM\" rmax2=\"$drMinM\" rmin1=\"0\" rmin2=\"0\" startphi=\"0\" z=\"$dxM2abs\"/>\n";

print def "<subtraction name =\"logicMotherSol${opt_T}\">
	<first ref=\"boxMotherSol${opt_T}\"/> 
	<second ref=\"coneMotherSol${opt_T}\"/> 
	<position unit=\"mm\" name=\"coneMotherPos${opt_T}\" x=\"0\" y=\"0\" z=\"0\"\/>
        <rotation unit=\"rad\" name=\"coneMotherRot${opt_T}\" x=\"0\" y=\"PI/2\" z=\"0\"/>
</subtraction>\n\n";
}
#------------------------------------------------------------------------------------------------------------------------------------------#



#-----------------------Defining solids of detector volume-----------------------------------------------------------------------------------#
for $j(0..$i-1){
print def "<box name=\"quartzRecSol_$index[$j]\" x=\"$dx[$j]\" y=\"$dy[$j]\" z=\"$dz[$j]\" lunit= \"mm\" />\n";

print def "<xtru name = \"quartzCutSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j]))),"\" y=\"",$dx[$j]*(0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j]))),"\" y=\"",$dx[$j]*(-0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(-0.5*tan(abs($quartzCutAngle[$j]))),"\" y=\"",$dx[$j]*(-0.5),"\" />
 <section zOrder=\"1\" zPosition=\"",$dy[$j]*(-0.5),"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"",$dy[$j]*(0.5),"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
</xtru>\n";

print def "<union name=\"quartzSol_$index[$j]\">
    <first ref=\"quartzRecSol_$index[$j]\"/>
    <second ref=\"quartzCutSol_$index[$j]\"/>
    <position name=\"quartzCutSolPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j])))+$dz[$j]*(0.5),"\"/>
    <rotation name=\"quartzCutSolRot_$index[$j]\" unit=\"rad\" x=\"PI/2\" y=\"0\" z=\"PI\"/> 
</union>\n";

$angle1= atan(abs($dxLg[$j]-$dxPmt[$j])/$dzLg[$j]);
$angle2= atan(abs($dyLg[$j]-$dyPmt[$j])/$dzLg[$j]);
print def "<trd name = \"lgLogicSol_$index[$j]\" z=\"$dzLg[$j]\" y1=\"",$dyLg[$j]+2*$dtWall[$j]/(cos($angle2)),"\" x1=\"",$dxLg[$j]+2*$dtWall[$j]/(cos($angle1)),"\" y2=\"",$dyPmt[$j]+2*$dtWall[$j]/(cos($angle2)),"\" x2=\"",$dxPmt[$j]+2*$dtWall[$j]/(cos($angle1)),"\" lunit= \"mm\"/>\n";



print def "<xtru name = \"refLogicSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j])+(($dtWall[$j]+$dtReflector[$j])/cos($lgTiltAngle[$j]+$refTopOpeningAngle[$j]))*cos($lgTiltAngle[$j]),"\" y=\"",$dzRef[$j]*0.5+(($dtWall[$j]+$dtReflector[$j])/cos($lgTiltAngle[$j]+$refTopOpeningAngle[$j]))*sin($lgTiltAngle[$j]),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j])-($dxLg[$j]+$dtWall[$j])*cos($lgTiltAngle[$j]),"\" y=\"",$dzRef[$j]*(0.5)-($dxLg[$j]+$dtWall[$j])*sin($lgTiltAngle[$j]),"\" />
 <twoDimVertex x=\"",$dx[$j]*(-0.5)-$dtWall[$j]/cos($lgTiltAngle[$j]),"\" y=\"",$dzRef[$j]*(-0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5)+($dtWall[$j]+$dtReflector[$j])/cos($refTopOpeningAngle[$j]),"\" y=\"",$dzRef[$j]*(-0.5),"\" />
 <section zOrder=\"1\" zPosition=\"",$dyLg[$j]*(-0.5)-$dtWall[$j],"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"",$dyLg[$j]*(0.5)+$dtWall[$j],"\" xOffset=\"",0,"\" yOffset=\"0\" scalingFactor=\"",1,"\"/>
</xtru>\n";

print def "<box name=\"pmtLogicSol_$index[$j]\" x=\"",$dxPmt[$j],"\" y=\"$dyPmt[$j]\" z=\"$dzPmt[$j]\" lunit= \"mm\" />\n";

print def "<union name=\"quartzLogicSol1_$index[$j]\">
    <first ref=\"quartzRecSol_$index[$j]\"/>
    <second ref=\"refLogicSol_$index[$j]\"/>
    <position name=\"refLogicSolPos_$index[$j]\" unit=\"mm\" x=\"",0,"\" y=\"0\" z=\"",0.5*$dz[$j]+0.5*$dzRef[$j],"\"/>
    <rotation name=\"refLogicSolRot_$index[$j]\" unit=\"rad\" x=\"PI/2\" y=\"",0,"\" z=\"0\"/> 
</union>\n";


print def "<union name=\"quartzLogicSol2_$index[$j]\">
    <first ref=\"quartzLogicSol1_$index[$j]\"/>
    <second ref=\"lgLogicSol_$index[$j]\"/>
   <position name=\"lgLogicSolPos_$index[$j]\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-$dzLg[$j]*0.5*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+$dzLg[$j]*0.5*cos($lgTiltAngle[$j]),"\"/>
    <rotation name=\"lgLogicSolRot_$index[$j]\" unit=\"rad\" x=\"0\" y=\"",$lgTiltAngle[$j]*(-1),"\" z=\"0\"/> 
</union>\n";

print def "<union name=\"quartzLogicSol_$index[$j]\">
    <first ref=\"quartzLogicSol2_$index[$j]\"/>
    <second ref=\"pmtLogicSol_$index[$j]\"/>
   <position name=\"pmtLogicSolPos_$index[$j]\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-($dzLg[$j]+$dzPmt[$j]*0.5)*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+($dzLg[$j]+$dzPmt[$j]*0.5)*cos($lgTiltAngle[$j]),"\"/>
    <rotation name=\"pmtLogicSolRot_$index[$j]\" unit=\"rad\" x=\"0\" y=\"",$lgTiltAngle[$j]*(-1),"\" z=\"0\"/> 
</union>\n";


print def "<trd name = \"lgSol_$index[$j]\" z=\"$dzLg[$j]\" y1=\"$dyLg[$j]\" x1=\"$dxLg[$j]\" y2=\"$dyPmt[$j]\" x2=\"$dxPmt[$j]\" lunit= \"mm\"/>\n";

print def "<subtraction name =\"lgSolSkin_$index[$j]\">
	<first ref=\"lgLogicSol_$index[$j]\"/> 
	<second ref=\"lgSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"lgSolPos_$index[$j]\" x=\"0\" y=\"0\" z=\"",0,"\"\/>
        <rotation unit=\"rad\" name=\"lgSolRot_$index[$j]\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";


print def "<xtru name = \"refSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j]),"\" y=\"",$dzRef[$j]*0.5,"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j])-($dxLg[$j])*cos($lgTiltAngle[$j]),"\" y=\"",$dzRef[$j]*(0.5)-($dxLg[$j])*sin($lgTiltAngle[$j]),"\" />
 <twoDimVertex x=\"",$dx[$j]*(-0.5),"\" y=\"",$dzRef[$j]*(-0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5),"\" y=\"",$dzRef[$j]*(-0.5),"\" />
 <section zOrder=\"1\" zPosition=\"",$dyLg[$j]*(-0.5),"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"",$dyLg[$j]*(0.5),"\" xOffset=\"",0,"\" yOffset=\"0\" scalingFactor=\"",1,"\"/>
</xtru>\n";


print def "<subtraction name =\"refSolSkin_$index[$j]\">
	<first ref=\"refLogicSol_$index[$j]\"/> 
	<second ref=\"refSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"refSolPos_$index[$j]\" x=\"0\" y=\"0\" z=\"",0,"\"\/>
        <rotation unit=\"rad\" name=\"refSolRot_$index[$j]\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";

print def "<subtraction name =\"refSol1_$index[$j]\">
	<first ref=\"refSol_$index[$j]\"/> 
	<second ref=\"quartzCutSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"quartzCutPos_$index[$j]\" x=\"0\" y=\"$dzRef[$j]*(-0.5)+$dx[$j]*(0.5*tan(abs($quartzCutAngle[$j])))\" z=\"",0,"\"\/>
        <rotation unit=\"rad\" name=\"quartzCutRot_$index[$j]\" x=\"0\" y=\"PI\" z=\"0\"/>
</subtraction>\n\n";




print def "<xtru name = \"reflectorSol_$index[$j]\" lunit= \"mm\" >
 <twoDimVertex x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j])+($dtReflector[$j]/cos($lgTiltAngle[$j]+$refTopOpeningAngle[$j]))*cos($lgTiltAngle[$j]),"\" y=\"",$dzRef[$j]*0.5+($dtReflector[$j]/cos($lgTiltAngle[$j]+$refTopOpeningAngle[$j]))*sin($lgTiltAngle[$j]),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5)+$dzRef[$j]*tan($refTopOpeningAngle[$j]),"\" y=\"",$dzRef[$j]*(0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5),"\" y=\"",$dzRef[$j]*(-0.5),"\" />
 <twoDimVertex x=\"",$dx[$j]*(0.5)+$dtReflector[$j]/cos($refTopOpeningAngle[$j]),"\" y=\"",$dzRef[$j]*(-0.5),"\" />
 <section zOrder=\"1\" zPosition=\"",$dyLg[$j]*(-0.5),"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1\" />
 <section zOrder=\"2\" zPosition=\"",$dyLg[$j]*(0.5),"\" xOffset=\"",0,"\" yOffset=\"0\" scalingFactor=\"",1,"\"/>
</xtru>\n";


print def "<subtraction name =\"refSolSkin1_$index[$j]\">
	<first ref=\"refSolSkin_$index[$j]\"/> 
	<second ref=\"reflectorSol_$index[$j]\"/> 
	<position name=\"reflectorSolPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",0,"\"/>
	<rotation name=\"reflectorSolRot_$index[$j]\" unit=\"rad\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";



print def "<cone name = \"pmtSol_$index[$j]\" rmin1=\"0\" rmax1=\"$drPmt[$j]\" rmin2=\"0\" rmax2=\"$drPmt[$j]\" z=\"$dzPmt[$j]\"
startphi=\"0\" deltaphi=\"2*PI\" aunit=\"rad\" lunit= \"mm\" />\n";
print def "<subtraction name =\"pmtSkinSol_$index[$j]\">
	<first ref=\"pmtLogicSol_$index[$j]\"/> 
	<second ref=\"pmtSol_$index[$j]\"/> 
	<position unit=\"mm\" name=\"pmtSolPos_$index[$j]\" x=\"0\" y=\"0\" z=\"",0,"\"\/>
        <rotation unit=\"rad\" name=\"pmtSolRot_$index[$j]\" x=\"0\" y=\"0\" z=\"0\"/>
</subtraction>\n\n";


}


#------------------------------------------------FIXME Define surface solids----------------------------------------------------------------------------------#
#<opticalsurface name="surf1" model="glisur" finish="polished" type="dielectric_dielectric" value="1.0"/>



#----------------------------------------------------------------------------------------------------------------------------------#

print def "\n</solids>";
close(def) or warn "close failed: $!";
##-----------------------------------------------End Defining solids.----------------------------------------------------------------------------------##


##--------------------------------------------------------------Start Structure.------------------------------------------------------------------------##
open(def, ">", "detector${opt_T}.gdml") or die "cannot open > detector${opt_T}.gdml: $!";
print def "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n
<!DOCTYPE gdml [
	<!ENTITY materials SYSTEM \"materialsNew.xml\"> 
	<!ENTITY solids${opt_T} SYSTEM \"solids${opt_T}.xml\"> 
]> \n
<gdml xmlns:gdml=\"http://cern.ch/2001/Schemas/GDML\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"schema/gdml.xsd\">\n

<define>
<constant name=\"PI\" value=\"1.*pi\"/>
</define>
&materials; 
&solids${opt_T};\n
<structure>\n";



for $j(0..$i-1){


print def "<volume name=\"quartzRecVol_$index[$j]\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"quartzSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"red\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$index[$j],"\"/>  
</volume>\n";

$k=$index[$j]+50;

print def "<volume name=\"refVol_$index[$j]\">
         <materialref ref=\"Air\"/>
         <solidref ref=\"refSol1_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"green\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$k,"\"/>  
</volume>\n";


print def "<volume name=\"refVolSkin_$index[$j]\">
         <materialref ref=\"Aluminium\"/>
         <solidref ref=\"refSolSkin1_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"brown\"/> 
</volume>\n";

print def "<volume name=\"reflectorVol_$index[$j]\">
         <materialref ref=\"Aluminium\"/>
         <solidref ref=\"reflectorSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"red\"/> 
</volume>\n";

$k=$index[$j]+50;
 
print def "<volume name=\"lgVol_$index[$j]\">
         <materialref ref=\"Air\"/>
         <solidref ref=\"lgSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"blue\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$k,"\"/>  
</volume>\n";

print def "<volume name=\"lgVolSkin_$index[$j]\">
         <materialref ref=\"Aluminium\"/>
         <solidref ref=\"lgSolSkin_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"brown\"/> 
</volume>\n";


$k=$index[$j]+50;
print def "<volume name=\"pmtVol_$index[$j]\">
         <materialref ref=\"Quartz\"/>
         <solidref ref=\"pmtSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"red\"/> 
 	 <auxiliary auxtype=\"SensDet\" auxvalue=\"planeDet\"/> 
	 <auxiliary auxtype=\"DetNo\" auxvalue=\"",$k,"\"/>  
</volume>\n";

print def "<volume name=\"pmtSkinVol_$index[$j]\">
         <materialref ref=\"Aluminium\"/>
         <solidref ref=\"pmtSkinSol_$index[$j]\"/> 
         <auxiliary auxtype=\"Color\" auxvalue=\"grey\"/> 
</volume>\n";







print def "<volume name=\"quartzVol_$index[$j]\">
         <materialref ref=\"Air\"/>
         <solidref ref=\"quartzLogicSol_$index[$j]\"/> 
         <physvol name=\"quartzRec_$index[$j]\">
			<volumeref ref=\"quartzRecVol_$index[$j]\"/>
			<position name=\"quartzRecPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"0\"/>
			<rotation name=\"quartzRecRot_$index[$j]\" unit=\"rad\" x=\"",0,"\" y=\"0\" z=\"0\"/>
</physvol> \n

<physvol name=\"ref_$index[$j]\">
			<volumeref ref=\"refVol_$index[$j]\"/>
			<position name=\"refPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]*(0.5),"\"/>
			<rotation name=\"refRot_$index[$j]\" unit=\"rad\" x=\"-PI/2\" y=\"0\" z=\"0\"/>
</physvol> \n
        <physvol name=\"refSkin_$index[$j]\">
			<volumeref ref=\"refVolSkin_$index[$j]\"/>
			<position name=\"refSkinPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]*(0.5),"\"/>
			<rotation name=\"refSkinRot_$index[$j]\" unit=\"rad\" x=\"-PI/2\" y=\"0\" z=\"0\"/>
</physvol> \n
      <physvol name=\"reflector_$index[$j]\">
			<volumeref ref=\"reflectorVol_$index[$j]\"/>
			<position name=\"reflectorPos_$index[$j]\" unit=\"mm\" x=\"0\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]*(0.5),"\"/>
			<rotation name=\"reflectorRot_$index[$j]\" unit=\"rad\" x=\"-PI/2\" y=\"0\" z=\"0\"/>
</physvol> \n


        <physvol name=\"lg_$index[$j]\">
			<volumeref ref=\"lgVol_$index[$j]\"/>
			<position name=\"lgPos_$index[$j]\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-$dzLg[$j]*0.5*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+$dzLg[$j]*0.5*cos($lgTiltAngle[$j]),"\"/>
			<rotation name=\"lgRot_$index[$j]\" unit=\"rad\" x=\"",0,"\" y=\"",$lgTiltAngle[$j],"\" z=\"",0,"\"/>
</physvol> \n
      <physvol name=\"lgSkin_$index[$j]\">
			<volumeref ref=\"lgVolSkin_$index[$j]\"/>
			<position name=\"lgSkinPos_$index[$j]\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-$dzLg[$j]*0.5*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+$dzLg[$j]*0.5*cos($lgTiltAngle[$j]),"\"/>
			<rotation name=\"lgSkinRot_$index[$j]\" unit=\"rad\" x=\"",0,"\" y=\"",$lgTiltAngle[$j],"\" z=\"",0,"\"/>
</physvol> \n

      <physvol name=\"pmt_$index[$j]\">
			<volumeref ref=\"pmtVol_$index[$j]\"/>
			<position name=\"pmtPos_$index[$j]\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-($dzLg[$j]+0.5*$dzPmt[$j])*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+($dzLg[$j]+0.5*$dzPmt[$j])*cos($lgTiltAngle[$j]),"\"/>
			<rotation name=\"pmtRot_$index[$j]\" unit=\"rad\" x=\"",0,"\" y=\"",$lgTiltAngle[$j],"\" z=\"",0,"\"/>
</physvol> \n
      <physvol name=\"pmtSkin_$index[$j]\">
			<volumeref ref=\"pmtSkinVol_$index[$j]\"/>
			<position name=\"pmtSkinPos_$index[$j]\" unit=\"mm\" x=\"",0.5*$dx[$j]+$dzRef[$j]*tan($refTopOpeningAngle[$j])-0.5*$dxLg[$j]*cos($lgTiltAngle[$j])-($dzLg[$j]+0.5*$dzPmt[$j])*sin($lgTiltAngle[$j]),"\" y=\"0\" z=\"",$dz[$j]*(0.5)+$dzRef[$j]-0.5*$dxLg[$j]*sin($lgTiltAngle[$j])+($dzLg[$j]+0.5*$dzPmt[$j])*cos($lgTiltAngle[$j]),"\"/>
			<rotation name=\"pmtSkinRot_$index[$j]\" unit=\"rad\" x=\"",0,"\" y=\"",$lgTiltAngle[$j],"\" z=\"",0,"\"/>
</physvol> \n  


</volume>\n";


}
print def "<volume name=\"logicMotherVol${opt_T}\"> 
	<materialref ref=\"Air\"/>
	<solidref ref=\"logicMotherSol${opt_T}\"/>\n";
for $j(0..$i-1){
print def "<physvol name=\"detector_$index[$j]\">
			<volumeref ref=\"quartzVol_$index[$j]\"/>
			<position name=\"detectorPos_$index[$j]\" unit=\"mm\" x=\"$x[$j]\" y=\"$y[$j]\" z=\"$z[$j]\"/>
			<rotation name=\"detectorRot_$index[$j]\" unit=\"rad\" x=\"",$rx[$j],"\" y=\"$ry[$j]\" z=\"$rz[$j]\"/>
</physvol> \n";
}
print def "</volume>";

#------------------------------------------------FIXME Define Materials----------------------------------------------------------------------------------#
#Skin surfaces are good for entire logical volumes, interacts on the surface, not the bulk
#<skinsurface name="skinsrf1" surfaceproperty="surf1" >
#  <volumeref ref="DetectorLogic"/>
#</skinsurface> 
#
#Border surfaces are good between multiple physical volumes (defined within a logical volume)
#<bordersurface name="bordersrf1" surfaceproperty="surf1" >
#  <physvolref ref="PhysPv1"/>
#  <physvolref ref="PhysPv2"/>
#</bordersurface> 

print def "\n</structure>\n\n";


##-----------------------------------------End structure.--------------------------------------------------------------------------##
print def "<setup name=\"logicMother${opt_T}\" version=\"1.0\">
	<world ref=\"logicMotherVol${opt_T}\"/>
</setup>\n
</gdml>";

close(def) or warn "close failed: $!";

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

=pod

=cut
