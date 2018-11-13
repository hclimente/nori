#!/usr/bin/env python
'''
Input variables:
    - Y_PRED: path to numpy array with prediction vector.
    - Y_TEST: path to numpy array with validation Y vector.
    - MODE: classification or regression.
    - MODEL: name of the method.
    - N: number of samples
    - D: number of features.
    - I: iteration number.
    - C: number of causal features, where 0 is the first one, 
    and (C - 1) is the last one.
Output files:
    - prediction_stats: path to a single-line tsv with the TSV results.
'''

import csv
import numpy as np
from sklearn.metrics import accuracy_score, mean_squared_error

y_test = np.load('${Y_TEST}')
y_pred = np.load('${Y_PRED}')

score = np.nan
if len(y_pred):
    if '${MODE}' == 'regression':
        score = mean_squared_error(y_test, y_pred, multioutput = 'uniform_average')
    else:
        score = accuracy_score(y_test, y_pred)

row = ['$MODEL', ${N}, ${D}, ${C}, ${I}, score ]

with open('prediction_stats', 'w', newline='') as f_output:
    tsv_output = csv.writer(f_output, delimiter='\t')
    tsv_output.writerow(row)