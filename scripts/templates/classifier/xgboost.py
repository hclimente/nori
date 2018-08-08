#!/usr/bin/env python
'''
Input variables:
    - SELECTED_FEATURES: path to the selected features.
    - X_TRAIN: path to numpy array with train X matrix.
    - Y_TRAIN: path to numpy array with train Y vector.
    - X_TEST: path to numpy array with validation X matrix.
    - C: number of causal features.
    - MODE: regression or classification.
Output files:
    - y_pred.npy
'''

import numpy as np
import xgboost as xgb
from sklearn.model_selection import GridSearchCV

selected_features = np.load("${SELECTED_FEATURES}")
x_train = np.load("${X_TRAIN}")
x_test = np.load("${X_TEST}")
y_train = np.load("${Y_TRAIN}")
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
    np.save('y_pred.npy', np.array([]))
    sys.exit(77)

grid_param = {
    'eta': [.3, .2, .1, .05, .01, .005],  # the training step for each iteration
}

clf = xgb.XGBClassifier(objective = 'multi:softmax') if '${MODE}' == 'classification' else xgb.XGBRegressor()

cv_clf = GridSearchCV(estimator = clf, param_grid = grid_param)
cv_clf.fit(x_train, y_train, num_class = len(np.unique(y_train)))

y_pred = cv_clf.predict(x_test) + 1
np.save('y_pred.npy', y_pred)


