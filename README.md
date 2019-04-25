# General Usage

The cadGeneratorV1.pl script uses the input file cadp.csv to produce equations.txt (for CAD), parameter.csv (for gdml generator) and detectorMotherP.csv (for gdml generator).

The gdmlGeneratorV1.pl script uses the parameter.csv (parameters for individual detectors in detector array) and detectorMotherP.csv (parameters for detector array mother volume) file to produce detector.gdml and solids.xml. These two files along with materialsNew.xml needs to copied to the remoll geometry folder for using in simulation.

Detailed instructions are given below.


# First execute the cad generator script

perl cadGeneratorV1.pl -F cadp.csv 
(produces equations.txt file and parameter.csv file corresponding to detector placed at 28.5 m downstream of origin.
Use cadp_shortened.csv to get detector placed at 27 m for a special case of target center at 0.575m. The cadp file needs to be tuned as upstream geometry changes.)
See cadp_documented.csv for description of parameters.

# GDML generator With No Optical Physics
perl gdmlGeneratorV1.pl -M detectorMotherP.csv -D parameter.csv
(produces solids.xml and detector.gdml)


# GDML generator With Optical Physics (Requires GEANT>=4.10.04.p02)
perl gdmlGeneratorV1_materials.pl -M detectorMotherP.csv -D parameter.csv -P qe.txt -U UVS_45total.txt -R MylarRef.txt
Warning: Cannot use parallel world in remoll if optical physics is enabled.

# Additional Flags
"-T suff" gives a suffix to all outputs.
"-L '12345opentransclosed6'" will give all rings with the number supplied, assuming the open section is desired, unless trans or closed is given, and open will always be given (can be fixed later if a problem)


# Viewing the Geometry

```
./remoll

/remoll/setgeofile geometry_test/detector.gdml

/run/initialize

/control/execute vis/Qt.mac
```

or use gdmlview (https://github.com/JeffersonLab/gdmlview)


# Placing the geometry in remoll

solids.xml, materialsNew.xml and detector.gdml file needs to be copied over to remoll geometry folder. The following lines needs to be added to mollerMother.gdml
 ```
 <physvol>
  <file name="<Remoll Geometry Folder>/detector.gdml"/>
  <positionref ref="detectorCenter"/>
  <rotation name="detectorRot" x="0" y="pi/2" z="0"/>
 </physvol>
 ```

# Example Macro for remoll
```
/remoll/setgeofile /home/rahmans/projects/def-jmammei/rahmans/geometry/geometry_optics_beam/mollerMother_merged1.gdml
/remoll/physlist/register QGSP_BERT
/remoll/physlist/parallel/enable
/remoll/parallel/setfile /home/rahmans/projects/def-jmammei/rahmans/geometry/geometry_optics_beam/mollerParallel.gdml
/run/numberOfThreads 5
/run/initialize
/remoll/addfield /home/rahmans/projects/def-jmammei/rahmans/map/default/text/blockyHybrid_rm_3.0.txt
/remoll/addfield /home/rahmans/projects/def-jmammei/rahmans/map/default/text/blockyUpstream_rm_1.1.txt
/remoll/evgen/set moller
/remoll/beamene 11 GeV
/remoll/beamcurr 70 microampere
/remoll/SD/enable_range 9000 80000
/remoll/SD/enable 32
/remoll/SD/detect boundaryhits 32
/remoll/kryptonite/set true
/remoll/filename /scratch/rahmans/scratch/backgroundStudy/beamUpstreamR0.0/moller/moller_1.root
/run/beamOn 50000
```               


# Current Detector Nomenclature: Interpreting the Output 
Detector IDs are assigned with the following convention
```
Different Rings:
5XXXX

Different Sectors:
Open: X0XXX
Transition: X1XXX
Closed: X2XXX

Different Parts:
quartz:   XX0XX  
reflector: XX1XX 
lg: XX2XX
```
The last two digits are increments within a ring.

For other rings, i don't have a sector label. So, for example 60001 is an open sector detector, 60002 is a transition sector detector and 60003 is a closed sector detector and the pattern repeats itself until detector number reaches 28.

Since ring 5 is segmented, there are 21 open sector detectors, 42 transition sector detectors and 21 closed sector detectors.

