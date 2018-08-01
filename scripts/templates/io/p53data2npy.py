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
import pandas as pd

mutants = pd.read_csv("${INPUT_FILE}", header = None, low_memory = False)

# encode protein active-status as 0/1
Y = mutants.iloc[:,-1]
Y = pd.factorize(Y)[0]
Y = np.expand_dims(Y, 0)

# encode matrix as float
mutants.drop(mutants.columns[[-1]], axis=1, inplace=True)
X = mutants.values
X[X == '?'] = 'nan'
X = X.astype('float')
X = X.T

# feature names as numbered strings
featnames = [ str(x) for x in mutants.columns.values ]

# remove samples with many nans
badfeats = np.sum(np.isnan(X), axis = 0) > 0
X = X[:, np.logical_not(badfeats)]

np.save("x.npy", X)
np.save("y.npy", Y)
np.save("featnames.npy", featnames)