#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x.
Output files:
    - all_features.npy: numpy array with the 0-based index of 
    the selected features.
'''

import numpy as np

x_train = np.load('${X_TRAIN}')

features = np.arange(x_train.shape[1])
np.save('all_features.npy', features)