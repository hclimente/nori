#!/usr/bin/env python
'''
Input variables:
    - N: desired number of samples.
    - D: desired number of features.
    - I: seed.
    - C: number of causal features.
Output files:
    - x_train.npy
    - y_train.npy
    - x_test.npy
    - y_test.npy
    - featnames.npy
'''

import numpy as np

np.random.seed(${I})
F = [(np.square, None), (np.sin, None), (np.cos, None)]
funs = np.random.choice(np.arange(len(F)), ${C})

print('Y = 0', end='')
for i in range(${C}):
    f,args = F[funs[i]]
    print(' + {}(x{},{})'.format(f.__name__, i, args), end='')

for set_type,n in zip(['train', 'test'], [${N}, 100]):

    x = np.random.random_integers(0, 2, size = (10 * n,${D}))
    y = np.zeros(10 * n)

    for i in range(${C}):
        f,args = F[funs[i]]
        y += f(x[:,i], args)

    y_bin = y > np.quantile(y, 0.9)

    unaffected = np.random.choice(np.where(np.logical_not(y_bin))[0], 
                                  size = int(n/10), replace=False)
    selected = np.concatenate((np.where(y_bin)[0], unaffected))
        
    np.save("x_{}.npy".format(set_type), x[selected,:].astype(float))
    np.save("y_{}.npy".format(set_type), y_bin[selected].astype(int))
    np.save("covars_{}.npy".format(set_type), np.array([]))

featnames = [ str(x) for x in np.arange(${D}) ]

np.save("featnames.npy", featnames)
