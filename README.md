# geometry_test

Usage:

cadGeneratorV1.pl and gdmlGeneratorV1_materials.pl execute the suggested commands without any flags using the indicated files as default settings. 

"-T suff" gives a suffix to all outputs.
"-L '12345opentransclosed6'" will give all rings with the number supplied, assuming the open section is desired, unless trans or closed is given, and open will always be given (can be fixed later if a problem)

perl cadGeneratorV1.pl -F cadp.csv 
(produces equations.txt file and parameter.csv file)

perl gdmlGeneratorV1.pl -M detectorMotherP.csv -D parameter.csv
(produces detector.gdml file)

perl gdmlGeneratorV1_materials.pl -M detectorMotherP.csv -D parameter.csv -P qe.txt -U UVS_45total.txt -R MylarRef.txt
(produces detector.gdml file)

To view geometry:

```
./remoll

/remoll/setgeofile geometry_test/detector.gdml

/run/initialize

/control/execute vis/Qt.mac
```
