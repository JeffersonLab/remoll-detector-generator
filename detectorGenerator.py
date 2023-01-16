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

args=parser.parse_args()


qz_thick = {{"R1F", 20},
            {"R1B", 20},
            {"R2F", 20},
            {"R2B", 20},
            {"R3F", 20},
            {"R3B", 20},
            {"R4F", 20},
            {"R4B", 20},
            {"R5F1", 17},
            {"R5F2", 17},
            {"R5F3", 17},
            {"R5B1", 17},
            {"R5B2", 17},
            {"R5B3", 17},
            {"R6F", 20},
            {"R6B", 20},
           }
qz_llc =  {{"R1F", np.array([])},
           {"R1B", np.array([])},
           {"R2F", np.array([])},
           {"R2B", np.array([])},
           {"R3F", np.array([])},
           {"R3B", np.array([])},
           {"R4F", np.array([])},
           {"R4B", np.array([])},
           {"R5F1", np.array([])},
           {"R5F2", np.array([])},
           {"R5F3", np.array([])},
           {"R5B1", np.array([])},
           {"R5B2", np.array([])},
           {"R5B3", np.array([])},
           {"R6F", np.array([])},
           {"R6B", np.array([])},
          }
qz_lrc = {{"R1F", np.array([])},
           {"R1B", np.array([])},
           {"R2F", np.array([])},
           {"R2B", np.array([])},
           {"R3F", np.array([])},
           {"R3B", np.array([])},
           {"R4F", np.array([])},
           {"R4B", np.array([])},
           {"R5F1", np.array([])},
           {"R5F2", np.array([])},
           {"R5F3", np.array([])},
           {"R5B1", np.array([])},
           {"R5B2", np.array([])},
           {"R5B3", np.array([])},
           {"R6F", np.array([])},
           {"R6B", np.array([])},
          }
qz_urc = {{"R1F", np.array([])},
           {"R1B", np.array([])},
           {"R2F", np.array([])},
           {"R2B", np.array([])},
           {"R3F", np.array([])},
           {"R3B", np.array([])},
           {"R4F", np.array([])},
           {"R4B", np.array([])},
           {"R5F1", np.array([])},
           {"R5F2", np.array([])},
           {"R5F3", np.array([])},
           {"R5B1", np.array([])},
           {"R5B2", np.array([])},
           {"R5B3", np.array([])},
           {"R6F", np.array([])},
           {"R6B", np.array([])},
          }
qz_ulc = {{"R1F", np.array([])},
           {"R1B", np.array([])},
           {"R2F", np.array([])},
           {"R2B", np.array([])},
           {"R3F", np.array([])},
           {"R3B", np.array([])},
           {"R4F", np.array([])},
           {"R4B", np.array([])},
           {"R5F1", np.array([])},
           {"R5F2", np.array([])},
           {"R5F3", np.array([])},
           {"R5B1", np.array([])},
           {"R5B2", np.array([])},
           {"R5B3", np.array([])},
           {"R6F", np.array([])},
           {"R6B", np.array([])},
          }
qz_zcom = {{"R1F", np.array([])},
           {"R1B", np.array([])},
           {"R2F", np.array([])},
           {"R2B", np.array([])},
           {"R3F", np.array([])},
           {"R3B", np.array([])},
           {"R4F", np.array([])},
           {"R4B", np.array([])},
           {"R5F1", np.array([])},
           {"R5F2", np.array([])},
           {"R5F3", np.array([])},
           {"R5B1", np.array([])},
           {"R5B2", np.array([])},
           {"R5B3", np.array([])},
           {"R6F", np.array([])},
           {"R6B", np.array([])},
          }



