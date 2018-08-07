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

F = [(np.square, None), (np.sin, None), (np.cos, None)]
funs = np.random.choice(np.arange(len(F)), ${C})

print('Y = 0', end='')
for i in range(${C}):
    print(' + {}(X[{},],{})'.format(f.__name__, F[funs[i]][0], F[funs[i]][1]), end='')

for set_type,n in zip(['train', 'test'], [${N}, 100]):

    x = 10 * np.random.randn(${D}, n)
    y = np.zeros((1, n))

    for i in range(${C}):
        f,args = F[funs[i]]
        
        y_x = f(x[i,:], args)
        # normalize
        y += (y_x - min(y_x))/(max(y_x) - min(y_x))

    np.save("x_{}.npy".format(set_type), x)
    np.save("y_{}.npy".format(set_type), y)


featnames = [ str(x) for x in np.arange(${D}) ]

np.save("featnames.npy", featnames)
