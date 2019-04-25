# General Usage

The cadGeneratorV1.pl script uses the input file cadp.csv to produce equations.txt (for CAD), parameter.csv (for gdml generator) and detectorMotherP.csv (for gdml generator).

The gdmlGeneratorV1.pl script uses the parameter.csv (parameters for individual detectors in detector array) and detectorMotherP.csv (parameters for detector array mother volume) file to produce detector.gdml and solids.xml. These two files along with materialsNew.xml needs to copied to the remoll geometry folder for using in simulation.

Detailed instructions are given below.


# First execute the cad generator script

perl cadGeneratorV1.pl -F cadp.csv 
(produces equations.txt file and parameter.csv file corresponding to detector placed at 28.5 m downstream of origin.
Use cadp_shortened.csv to get detector placed at 27 m for a special case of target center at 0.575m. The cadp file needs to be tuned as upstream geometry changes.)

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
  <file name="/home/rahmans/projects/def-jmammei/rahmans/geometry/geometry_optics_beam/detector.gdml"/>
  <positionref ref="detectorCenter"/>
  <rotation name="detectorRot" x="0" y="pi/2" z="0"/>
 </physvol>
 ```





