#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x.
    - Y_TRAIN: path of a numpy array with y.
    - C: number of features to select.
Output files:
    - features_lars.npy: numpy array with the 0-based index of 
    the selected features.
'''

import spams
import numpy as np

x_train = np.load('${X_TRAIN}')
x_train = np.asfortranarray(x_train)
y_train = np.load('${Y_TRAIN}')
y_train  = np.expand_dims(y_train, 1)
y_train = np.asfortranarray(y_train)

alpha = spams.lasso(y_train, D = x_train, return_reg_path = False, L = ${C}, lambda1 = 10e6)
features = np.nonzero(alpha)[0]
np.save('features_lars.npy', features)