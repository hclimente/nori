#!/usr/bin/env python
'''
Input variables:
    - X_TRAIN: path of a numpy array with x for training.
    - X_TEST: path of a numpy array with x for testing.
Output files:
    - x_train_normalized.npy
    - x_test_normalized.npy
'''

import numpy as np

x_train = np.load('${X_TRAIN}')
x_test = np.load("${X_TEST}")

mean = np.mean(x_train, axis = 0)
std = np.sd(x_train, axis = 0)

x_train = (x_train - mean)/sd
x_test = (x_test - mean)/sd

np.save('x_train_normalized.npy', x_train)
np.save('x_test_normalized.npy', x_test)