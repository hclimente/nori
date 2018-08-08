#!/usr/bin/env python
'''
Input variables:
    - INPUT_FILE: input mat file.
Output files:
    - x.npy
    - y.npy
    - featnames.npy
'''

import numpy as np
from scipy import io as spio

data = spio.loadmat("${INPUT_FILE}")

x = data["X"]
y = data["Y"].squeeze()

d = x.shape[1]
featname = [('%d' % i) for i in range(1, d+1)]

np.save("x.npy", x)
np.save("y.npy", y)
np.save("featnames.npy", featname)