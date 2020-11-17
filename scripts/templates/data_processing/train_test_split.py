#!/usr/bin/env python
'''
Input variables:
    - X: path of a numpy array with x.
    - Y: path of a numpy array with y.
    - SPLIT: [0-1] proportion of test dataset.
    - SEED: random seed.
Output files:
    - x_train.npy
    - y_train.npy
    - x_test.npy
    - y_test.npy
'''

import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.utils import resample

np.random.seed(${SEED})
x = np.load("${X}")
y = np.load("${Y}")

n = x.shape[0]
perm = np.random.permutation(n)
x = x[perm,:]
y = y[perm]

x_train, x_test, y_train, y_test = train_test_split(x, y, test_size = ${SPLIT})

np.save("x_train.npy", x_train)
np.save("x_test.npy", x_test)
np.save("y_train.npy", y_train)
np.save("y_test.npy", y_test)
