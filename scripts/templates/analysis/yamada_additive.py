#!/usr/bin/env python
'''
Input variables:
    - N: desired number of samples.
    - D: desired number of features.
Output files:
    - x_train.npy
    - y_train.npy
    - x_test.npy
    - y_test.npy
    - featnames.npy
'''

import numpy as np

def additive(x1, x2, x3, x4):
    e = np.random.normal(size = x1.shape)
    return - 2*np.sin(2*x1) + np.square(x2) + x3 + np.exp(-x4) + e

for set_type in ['train', 'test']:
    x = np.random.rand(${D}, ${N})
    y = additive(x[0,:], x[1,:], x[2,:], x[3,:])
    y = np.expand_dims(y, 0)

    np.save("x_{}.npy".format(set_type), x)
    np.save("y_{}.npy".format(set_type), y)

featnames = [ str(x) for x in np.arange(${D}) ]

np.save("featnames.npy", featnames)