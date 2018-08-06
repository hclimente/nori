#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x.
    - Y_TRAIN: path of a numpy array with y.
    - FEATNAMES: path of a numpy array with feature names.
    - MODE: regression or classification.
    - HL_SELECT: number of features to select.
Output files:
    - selected_features.npy: numpy array with the 0-based index of 
    the selected features.
'''

import numpy as np
from lHSICLasso import *

X_in = np.load("${X_TRAIN}")
Y_in = np.load("${Y_TRAIN}")
featname = np.load("${FEATNAMES}")
ykernel = 'Gauss' if '${MODE}' == 'regression' else 'Delta'

try:
    _, _, A, _ = lhsiclasso(X_in, Y_in, numFeat=${HL_SELECT}, numClusters=5, ykernel = ykernel)
except MemoryError:
    import sys, traceback
    traceback.print_exc()
    np.save('selected_features.npy', np.array([]))
    sys.exit(77)

np.save('selected_features.npy', A)
