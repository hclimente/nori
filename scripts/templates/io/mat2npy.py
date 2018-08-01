#!/usr/bin/env python

import numpy as np
from scipy import io as spio

data = spio.loadmat("$input_file")

x = data["X"].T
y = data["Y"].T

d = x.shape[0]
featname = [('%d' % i) for i in range(1,d+1)]

np.save("x.npy", x)
np.save("y.npy", y)
np.save("featnames.npy", featname)