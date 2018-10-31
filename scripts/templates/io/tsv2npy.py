#!/usr/bin/env python
'''
Input variables:
    - INPUT_FILE: input expression file.
    - COL_FEATS: column of the expression file with the feature names.
    - METADATA: metadata file.
    - COL_ID: column of the metadata file with the cell identifier.
    - COL_Y: column of the metadata file with the outcome variable.
Output files:
    - x.npy
    - y.npy
    - featnames.npy
'''

import numpy as np
import pandas as pd

# read gene expression
expression = pd.read_csv('${INPUT_FILE}', sep = '\t')
featnames = expression.pop('${COL_FEATS}').tolist()
x = expression.values.T

# read phenotypes
meta = pd.read_csv('${METADATA}', sep = '\t')
meta = meta.set_index('${COL_ID}')
cell_lines = meta['${COL_Y}'].to_dict()
y = np.array([ cell_lines.get(c,None) for c in expression.columns ])
y = pd.factorize(y)[0]

np.save("x.npy", x)
np.save("y.npy", y)
np.save("featnames.npy", featnames)
