#!/usr/bin/env python
'''
Input variables:
    - SELECTED_FEATURES: path to the selected features.
    - X_TRAIN: path to numpy array with train X matrix.
    - Y_TRAIN: path to numpy array with train Y vector.
    - X_TEST: path to numpy array with validation X matrix.
    - C: number of causal features.
Output files:
    - predictions.npy
'''

import numpy as np
import xgboost as xgb
from sklearn.model_selection import GridSearchCV

selected_features = np.load("${SELECTED_FEATURES}")
x_train = np.load("${X_TRAIN}").T
x_test = np.load("${X_TEST}").T
y_train = np.load("${Y_TRAIN}").squeeze()
y_train -= 1

try:
    if not selected_features.any():
        raise IndexError('No selected features')
    selected_features = selected_features[0:${C}]
    x_train = x_train[:, selected_features]
    x_test = x_test[:, selected_features]
except IndexError:
    import sys, traceback
    traceback.print_exc()
    np.save('predictions.npy', np.array([]))
    sys.exit(77)

dtrain = xgb.DMatrix(x_train, label=y_train)
dtest = xgb.DMatrix(x_test)

param = {
    'max_depth': 3,  # the maximum depth of each tree
    'eta': 0.3,  # the training step for each iteration
    'silent': 1,  # logging mode - quiet
    'objective': 'multi:softprob',  # error evaluation for multiclass training
    'num_class': len(np.unique(y_train))}  # the number of classes that exist in this datset
num_round = 20  # the number of training iterations

bst = xgb.train(param, dtrain, num_round)
y_p = bst.predict(dtest)
y_pred = np.argmax(y_p, axis = 1) + 1
np.save('predictions.npy', y_pred)




