#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x.
    - Y_TRAIN: path of a numpy array with y.
    - FEATNAMES: path of a numpy array with feature names.
    - MODE: regression or classification.
    - HL_SELECT: number of features to select.
    - HL_B: size of the block.
    - HL_M: number of permutations.
Output files:
    - selected_features.npy: numpy array with the 0-based index of 
    the selected features.
'''

import numpy as np
from pyHSICLasso import HSICLasso

hl = HSICLasso()

hl.X_in = np.load("${X_TRAIN}")
hl.Y_in = np.load("${Y_TRAIN}")
hl.featname = np.load("${FEATNAMES}")

d,n = hl.X_in.shape

if $HL_B:
    discard = np.random.choice(np.arange(n), n % $HL_B, replace = False)
    hl.X_in = np.delete(hl.X_in, discard, 1)
    hl.Y_in = np.delete(hl.Y_in, discard, 1)

try:
    hl.${MODE}($HL_SELECT, B = $HL_B, M = $HL_M)
except MemoryError:
    import sys, traceback
    traceback.print_exc()
    sys.exit(77)

np.save('selected_features.npy', hl.A)