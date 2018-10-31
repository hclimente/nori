#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with _train
    - Y_TRAIN: path of a numpy array with y.
    - MODE: regression or classification.
    - C: number of features to select.
Output files:
    - features_mrmr.npy: numpy array with the 0-based index of 
    the selected features.
'''

import numpy as np
import subprocess

x_train = np.load("${X_TRAIN}")
y_train = np.load("${Y_TRAIN}")

# write dataset
ds = np.hstack((np.expand_dims(y_train, axis = 1), x_train))
cols = 'y,' + ','.join([ str(feat) for feat in np.arange(x_train.shape[1])])

np.savetxt('dataset.csv', ds, header = cols, fmt='%1.3f',
           delimiter = ',', comments='')
discretization = '-t 0' if '${MODE}' == 'regression' else ''

# run mrmr
samples,features = x_train.shape
out = subprocess.check_output(['mrmr', '-i', 'dataset.csv', discretization, '-n', 
                               '${C}', '-s', str(samples), '-v', str(features)])

flag = False
features = []
for line in out.decode('ascii').split('\\n'):
    if flag and 'Name' not in line:
        if not line:
            flag = False
        else:
            f = line.split('\\t')[2].strip()
            features.append(int(f))
    elif 'mRMR features' in line:
        flag = True

feats_pred = np.array(features)
np.save('features_mrmr.npy', feats_pred)
