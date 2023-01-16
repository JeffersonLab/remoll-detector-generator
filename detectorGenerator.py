#!/usr/bin/env python

import sys
import os
import subprocess
import math
import time
import argparse

parser = argparse.ArgumentParser(description="Generate a detector array based on the following arguments")
parser.add_argument("--generate-quartz", dest="generate_quartz", action="store", required=False, default=True, help="Set to true if you want to generate all the quartz pieces")
parser.add_argument("--generate-lg", dest="generate_lg", action="store", required=False, default=False, help="Set to true if you want to generate all lightguides")
parser.add_argument("--generate-support", dest="generate_support", action="store", required=False, default=False, help="Set to true if you want to generate all supports")

args=parser.parse_args()




