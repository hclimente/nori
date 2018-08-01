#!/usr/bin/env python
'''
Input variables:
    - SELECTED_FEATURES: path to the selected features.
    - MODEL: name of the method.
    - N: number of samples
    - D: number of features.
    - I: iteration number.
    - C: number of causal features, where 0 is the first one, 
    and (C - 1) is the last one.
Output files:
    - feature_stats: path to a single-line tsv with the TSV results.
'''

import csv
import numpy as np

feats_true = np.arange(${C})
feats_pred = np.load('${SELECTED_FEATURES}')
feats_top = feats_pred[0:${C}]

tpr = np.nan
if len(feats_top):
    tpr = len(np.intersect1d(feats_true, feats_top)) / len(feats_true)

row = ['${MODEL}', ${N}, ${D}, ${C}, len(feats_pred), ${I}, tpr ]

with open('feature_stats', 'w', newline='') as f_output:
    tsv_output = csv.writer(f_output, delimiter='\t')
    tsv_output.writerow(row)