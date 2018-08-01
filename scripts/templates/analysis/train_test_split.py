#!/usr/bin/env python
'''
Input variables:
    - X: path of a numpy array with x.
    - Y: path of a numpy array with y.
    - SPLIT: [0-1] proportion of test dataset.
Output files:
    - x_train.npy
    - y_train.npy
    - x_test.npy
    - y_test.npy
'''

import numpy as np
from sklearn.model_selection import train_test_split

x = np.load("${X}").T
y = np.load("${Y}").T

n = x.shape[0]
perm = np.random.permutation(n)
x = x[perm,:]
y = y[perm,:]

x_train, x_val, y_train, y_val = train_test_split(x, y, test_size = ${SPLIT})

np.save("x_train.npy", x_train.T)
np.save("x_val.npy", x_val.T)
np.save("y_train.npy", y_train.T)
np.save("y_val.npy", y_val.T)