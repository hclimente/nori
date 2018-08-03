#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x.
    - Y_TRAIN: path of a numpy array with y.
    - MODE: regression or classification.
    - C: number of features to select.
Output files:
    - selected_features.npy: numpy array with the 0-based index of 
    the selected features.
'''

import numpy as np
import subprocess

x = np.load("${X_TRAIN}")
y = np.load("${Y_TRAIN}")

# write dataset
ds = np.vstack((y,x)).T
cols = 'y,' + ','.join([ str(x) for x in np.arange(x.shape[0])])

np.savetxt('dataset.csv', ds, header = cols, fmt='%1.3f',
           delimiter = ',', comments='')
discretization = '-t 0' if '${MODE}' == 'regression' else ''

# run mrmr
features,samples = x.shape
out = subprocess.check_output(['mrmr', '-i', 'dataset.csv', discretization, '-n', 
                               '${C}', '-s', str(samples), '-v', str(features)])

flag = False
features = []
for line in out.decode('ascii').split('\\n'):
    if flag and len(features) < ${C} and 'Name' not in line:
        f = line.split('\\t')[2].strip()
        features.append(int(f))
    elif 'mRMR features' in line:
        flag = True

feats_pred = np.array(features)
np.save('selected_features.npy', feats_pred)
