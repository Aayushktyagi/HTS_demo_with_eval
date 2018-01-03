#script to remove time stamp
import numpy as np
filename="/home/aayush/Downloads/HTS-demo_CMU-ARCTIC-SLT/data/labels/texttospeech_lab/make_full_labels-master/example/test_1.lab"
output_filename="/home/aayush/Downloads/HTS-demo_CMU-ARCTIC-SLT/data/labels/texttospeech_lab/make_full_labels-master/example/test_rem_timestamp.lab"
f = open(filename, "r")
g = open(output_filename, "w")

for line in f:
    if line.strip():
        g.write("\t".join(line.split()[2:]) + "\n")

f.close()
g.close()
