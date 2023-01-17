#!/usr/bin/env python

import sys
import os
import subprocess
import math
import time
import argparse
import numpy as np
import pandas as pd

parser = argparse.ArgumentParser(description="Generate a detector array based on the following arguments")
parser.add_argument("--generate-quartz", dest="generate_quartz", action="store", required=False, default=True, help="Set to true if you want to generate all the quartz pieces")
parser.add_argument("--generate-lg", dest="generate_lg", action="store", required=False, default=False, help="Set to true if you want to generate all lightguides")
parser.add_argument("--generate-support", dest="generate_support", action="store", required=False, default=False, help="Set to true if you want to generate all supports")
parser.add_argument("--front-quartz", dest="front_quartz", action="store", required=False, default="FF.csv", help="Set the csv file containing coordinates of quartz piece of front modules")
parser.add_argument("--back-quartz", dest="back_quartz", action="store", required=False, default="BF.csv", help="Set the csv file containing coordinates of quartz piece of back modules")
parser.add_argument("--out-file", dest="out_file", action="store", required=False, default="detector.gdml", help="Set the name of output gdml file")
args=parser.parse_args()

front_quartz = pd.read_csv(args.front_quartz)
back_quartz  = pd.read_csv(args.back_quartz)

front_quartz = front_quartz[front_quartz["Part"].str.contains("Quartz:1", na=False)]
back_quartz  = back_quartz[back_quartz["Part"].str.contains("Quartz:1", na=False)]

gdml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>     \n\n\
<gdml xmlns:gdml=\"http://cern.ch/2001/Schemas/GDML\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\
xsi:noNamespaceSchemaLocation=\"http://service-spi.web.cern.ch/service-spi/app/releases/GDML/schema/gdml.xsd\"> \n\n\
<define>                                               \n\
</define>                                              \n\n\
<materials>                                            \n\
</materials>                                           \n\n"

gdml += "<solids> \n\n"

ring = [5,5,5,6,4,3,2,1]
if args.generate_quartz:
  for i in range(0, len(front_quartz.index)):
    gdml += "<xtru name=\"quartz_"+str(ring[i])+"\"> \n\
  <twoDimVertex x=\""+str(front_quartz['USLCWz'].iloc[i])+"\" y=\""+str(front_quartz['USLCWy'].iloc[i])+"\"/> \n\
  <twoDimVertex x=\""+str(front_quartz['DSLCWz'].iloc[i])+"\" y=\""+str(front_quartz['DSLCWy'].iloc[i])+"\"/> \n\
  <twoDimVertex x=\""+str(front_quartz['DSUCWz'].iloc[i])+"\" y=\""+str(front_quartz['DSUCWy'].iloc[i])+"\"/> \n\
  <twoDimVertex x=\""+str(front_quartz['USUCWz'].iloc[i])+"\" y=\""+str(front_quartz['USUCWy'].iloc[i])+"\"/> \n\
  <section zOrder=\"0\" zPosition=\""+str(front_quartz['USLCWx'].iloc[i])+"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1.0\"/> \n\
  <section zOrder=\"1\" zPosition=\""+str(front_quartz['USLCCWx'].iloc[i])+"\" xOffset=\"0\" yOffset=\"0\" scalingFactor=\"1.0\"/> \n\
</xtru> \n\n"

gdml += "</solids>\n\n"

   
    
         

f = open(args.out_file, "w")
f.write(gdml)
f.close()
        
