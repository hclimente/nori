#!/usr/bin/env python
'''
Input variables:
    - INPUT_FILE: input expression file.
    - metadata.tsv
Output files:
    - x.npy
    - y.npy
    - featnames.npy
'''

import numpy as np
import pandas as pd

# read gene expression
expression = pd.read_csv('${INPUT_FILE}', sep = '\t')
featnames = expression.pop('tracking_id').tolist()
x = expression.values

# read phenotypes
meta = pd.read_csv('${METADATA}', sep = '\t')
meta = meta.set_index('UID')
cell_lines = meta['C4_Cell_Line_ID'].to_dict()
y = np.array([ cell_lines[c] for c in expression.columns ])
y = pd.factorize(y)[0]

np.save("x.npy", x)
np.save("y.npy", y)
np.save("featnames.npy", featnames)