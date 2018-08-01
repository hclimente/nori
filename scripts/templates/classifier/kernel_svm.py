#!/usr/bin/env python
'''
Input variables:
    - SELECTED_FEATURES: path to the selected features.
    - X_TRAIN: path to numpy array with train X matrix.
    - Y_TRAIN: path to numpy array with train Y vector.
    - X_VAL: path to numpy array with validation X matrix.
    - MODE: regression or classification.
    - C: number of causal features.
Output files:
    - predictions.npy
'''


import numpy as np
from sklearn import svm
from sklearn.model_selection import GridSearchCV

selected_features = np.load("${SELECTED_FEATURES}")
x_train = np.load('${X_TRAIN}').T

try:
    if not selected_features.any():
        raise IndexError('No selected features')
    selected_features = selected_features[0:${C}]
    x_train = x_train[:, selected_features]
except IndexError:
    import sys, traceback
    traceback.print_exc()
    sys.exit(77)

y_train = np.load("${Y_TRAIN}").squeeze()

if '${MODE}' == 'regression':
    clf = svm.SVR()
elif '${MODE}' == 'classification':
    clf = svm.SVC()

Cs = np.logspace(-6, 1, 10)
clf = GridSearchCV(estimator=clf, param_grid=dict(C=Cs))
clf.fit(x_train, y_train)

x_val = np.load("${X_VAL}").T
x_val = x_val[:, selected_features]
predictions = clf.predict(x_val)
np.save('predictions.npy', predictions)