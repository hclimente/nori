#!/usr/bin/env python
'''
Input variables:
    - X: path of a numpy array with x.
Output files:
    - x_normalized.npy
'''

import numpy as np

x = np.load('${X}')

mean = np.mean(x, axis = 0)
std = np.std(x, axis = 0)

x_norm = ((x - mean)/(std + 0.0001))

np.save('x_normalized.npy', x_norm)