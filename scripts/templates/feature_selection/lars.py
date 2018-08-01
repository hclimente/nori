#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x.
    - Y_TRAIN: path of a numpy array with y.
    - C: number of features to select.
Output files:
    - features.npy: numpy array with the 0-based index of 
    the selected features.
'''

import numpy as np
from sklearn.linear_model import Lars
from sklearn.feature_selection import SelectFromModel

x_train = np.load('${X_TRAIN}').T
y_train = np.load('${Y_TRAIN}').squeeze()

clf = Lars(n_nonzero_coefs = ${C})
clf.fit(x_train, y_train)

sfm = SelectFromModel(clf, prefit = True)
features = np.where(sfm.get_support())[0]
np.save('features.npy', features)