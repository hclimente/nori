#!/usr/bin/env python
'''
Input variables:
    - MODEL: name of the method.
    - N: number of samples
    - D: number of features.
    - I: iteration number.
    - C: number of causal features, where 0 is the first one, 
    and (C - 1) is the last one.
Input files:
    - features_*: Several runs of a feature extraction algorithm 
    to evaluate stability.
Output files:
    - feature_stats: path to a single-line tsv with the TSV results.
'''

import csv
import numpy as np
from glob import glob

features_files = glob('features_*')
extracted_features = []
jaccards = []
for file in features_files:
    ef = np.load(file)

    for ef2 in extracted_features:
        intersection = np.intersect1d(ef, ef2)
        union = np.union1d(ef, ef2)
        J = len(intersection)/len(union)
        jaccards.append(J)

    extracted_features.append(ef)

with open('stability_stats', 'w', newline='') as f_output:
    tsv_output = csv.writer(f_output, delimiter='\t')
    for J in jaccards:
        row = ['${MODEL}', ${N}, ${D}, ${C}, ${I}, len(features_files), J ]
        tsv_output.writerow(row)