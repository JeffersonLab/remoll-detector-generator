# General Usage

The cadGeneratorV1.pl script uses the input file cadp.csv to produce equations.txt (for CAD), parameter.csv (for gdml generator) and detectorMotherP.csv (for gdml generator).

The gdmlGeneratorV1.pl script uses the parameter.csv (parameters for individual detectors in detector array) and detectorMotherP.csv (parameters for detector array mother volume) file to produce detector.gdml and solids.xml. These two files along with materialsNew.xml needs to copied to the remoll geometry folder for using in simulation.

Detailed instructions are given below.


# First execute the cad generator script

```
perl cadGeneratorV1.pl -F cadp.csv 
```
(produces equations.txt file and parameter.csv file corresponding to detector placed at 28.5 m downstream of origin.
Use cadp_shortened.csv to get detector placed at 27 m for a special case of target center at 0.575m. The cadp file needs to be tuned as upstream geometry changes.)
See cadp_documented.csv for description of parameters.

# GDML generator With No Optical Physics
```
perl gdmlGeneratorV1.pl -M detectorMotherP.csv -D parameter.csv
```
(produces solids.xml and detector.gdml)


# GDML generator With Optical Physics (Requires GEANT>=4.10.04.p02)
```
perl gdmlGeneratorV1_materials.pl -M detectorMotherP.csv -D parameter.csv -P qe.txt -U UVS_45total.txt -R MylarRef.txt
```
Warning: With Geant < 4.10.06.p01 you cannot use parallel world in remoll if optical physics is enabled.

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
5XXXXX

Different Septants and Coils:
Septant: XN0XXX for septant N (1-7)
Coils: X0NXXX for coil N (1-7)

Different Sectors:
Closed: XXX0XX
Transition-: XXX1XX
Open: XXX2XX
Transition+: XXX3XX

Different Segments for ring 5:
Phi-: XXXX0X
Phi0: XXXX1X
Phi+: XXXX2X

N.B. Currently sector labels only exist for ring 5. For all other rings, rely on repeating pattern to identify sector. For example in ring 6,  60001 is an open sector detector, 60002 is a transition sector detector and 60003 is a closed sector detector and the pattern repeats itself until detector number reaches 28.

Different Parts:
pmt:   XXXXX0
quartz:   XXXXX1
reflector: XXXXX2
lg: XXXXX3
```

# Quick Notes
"-T suff" gives a suffix to all outputs. "-L '12345opentransclosed6'" will give all rings with the number supplied, assuming the open section is desired, unless trans or closed is given, and open will always be given (can be fixed later if a problem)

"-I suff" will place the PMTs inline with the light guides.

perl cadGeneratorV1.pl -F cadp.csv (produces equations.txt file and parameter.csv file)

perl gdmlGeneratorV1.pl -M detectorMotherP.csv -D parameter.csv (produces detector.gdml file)

perl gdmlGeneratorV1_materials.pl -M detectorMotherP.csv -D parameter.csv -P qe.txt -U UVS_45total.txt -R MylarRef.txt (produces detector.gdml file)
