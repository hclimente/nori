#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x.
    - Y_TRAIN: path of a numpy array with y.
    - FEATNAMES: path of a numpy array with feature names.
    - MODE: regression or classification.
    - HL_SELECT: number of features to select.
Output files:
    - features_lhl.npy: numpy array with the 0-based index of 
    the selected features.
'''

import numpy as np
from pyHSICLasso.api import lHSICLasso

hl = lHSICLasso()

hl.X_in = np.load("${X_TRAIN}").T
hl.Y_in = np.load("${Y_TRAIN}").T
hl.Y_in = np.expand_dims(hl.Y_in, 0)
hl.featname = np.load("${FEATNAMES}")

try:
    hl.${MODE}($HL_SELECT)
except MemoryError:
    import sys, traceback
    traceback.print_exc()
    np.save('features_lhl.npy', np.array([]))
    sys.exit(77)

np.save('features_lhl.npy', hl.A)
