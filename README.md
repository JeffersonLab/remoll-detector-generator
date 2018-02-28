# geometry_test

Usage:

perl cadGeneratorV1.pl -F cadp.csv 
(produces equations.txt file and parameter.csv file)

perl gdmlGeneratorV1.pl -M detectorMotherP.csv -D parameter.csv
(produces detector.gdml file)

perl gdmlGeneratorV1_materials.pl -M detectorMotherP.csv -D parameter.csv -P qe.txt -U UVS45_total.txt -R MylarRef.txt
(produces detector.gdml file)

To view geometry:

```
./remoll

/remoll/setgeofile geometry_test/detector.gdml

/run/initialize

/control/execute vis/Qt.mac
```
