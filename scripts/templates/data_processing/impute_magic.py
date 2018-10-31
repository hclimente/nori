#!/usr/bin/env python
'''
Input variables:
    - X: file with single-cell data to impute.
Output files:
    - x_imputed.npy
'''

import magic
import numpy as np

raw_expression = np.load('${X}')

magic_op = magic.MAGIC()
imputed_expression = magic_op.fit_transform(raw_expression, genes = 'all_genes')

np.save('x_imputed.npy', imputed_expression)