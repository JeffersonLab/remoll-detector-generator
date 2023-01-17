#!/usr/bin/env python

import sys
import os
import subprocess
import math
import time
import argparse
import numpy as np

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

front_quartz = front_quartz[front["Part"].str.contains("Quartz:1", na=False)]
back_quartz  = back_quartz[back["Part"].str.contains("Quartz:1", na=False)]

gdml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>             \n
        <gdml xmlns:gdml=\"http://cern.ch/2001/Schemas/GDML\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \
         xsi:noNamespaceSchemaLocation=\"http://service-spi.web.cern.ch/service-spi/app/releases/GDML/schema/gdml.xsd\"> \n
        <define>                                               \n
        </define>                                              \n
        <materials>                                            \n
        </materials>                                           \
       "

f = open(args.out_file, "w")
f.write(gdml)
f.close()
        
