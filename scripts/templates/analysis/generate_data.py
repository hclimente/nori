#!/usr/bin/env python
'''
Input variables:
    - N: desired number of samples.
    - D: desired number of features.
    - C: number of causal features.
Output files:
    - x_train.npy
    - y_train.npy
    - x_test.npy
    - y_test.npy
    - featnames.npy
'''

import numpy as np

x_train = 10 * np.random.randn(${D}, ${N})
x_val = 10 * np.random.randn(${D}, 100)

F = [(np.square, None), (np.sin, None), (np.cos, None)]
funs = np.random.choice(np.arange(len(F)), ${C})

y_train = np.zeros((1, ${N}))
y_val = np.zeros((1, 100))

print('Y = 0', end='')
for i in range(${C}):
    f,args = F[funs[i]]
    print(' + {}(X[{},],{})'.format(f.__name__, i, args), end='')
    yx_train = f(x_train[i,:], args)
    yx_val = f(x_val[i,:], args)
    # normalize by the variance
    y_train += (yx_train - min(yx_train))/(max(yx_train) - min(yx_train))
    y_val += (yx_val - min(yx_val))/(max(yx_val) - min(yx_val))

featnames = [ str(x) for x in np.arange(${D}) ]

np.save("x_train.npy", x_train)
np.save("y_train.npy", y_train)
np.save("x_val.npy", x_val)
np.save("y_val.npy", y_val)
np.save("featnames.npy", featnames)