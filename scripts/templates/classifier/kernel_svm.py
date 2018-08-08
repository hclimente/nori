#!/usr/bin/env python
'''
Input variables:
    - SELECTED_FEATURES: path to the selected features.
    - X_TRAIN: path to numpy array with train X matrix.
    - Y_TRAIN: path to numpy array with train Y vector.
    - X_TEST: path to numpy array with validation X matrix.
    - MODE: regression or classification.
    - C: number of causal features.
Output files:
    - y_pred.npy
'''

import numpy as np
from sklearn import svm
from sklearn.model_selection import GridSearchCV

selected_features = np.load("${SELECTED_FEATURES}")
x_train = np.load('${X_TRAIN}')

try:
    if not selected_features.any():
        raise IndexError('No selected features')
    selected_features = selected_features[0:${C}]
    x_train = x_train[:, selected_features]
except IndexError:
    import sys, traceback
    traceback.print_exc()
    np.save('y_pred.npy', np.array([]))
    sys.exit(77)

y_train = np.load("${Y_TRAIN}")

if '${MODE}' == 'regression':
    clf = svm.SVR()
elif '${MODE}' == 'classification':
    clf = svm.SVC()

Cs = np.logspace(-6, 1, 10)
cv_clf = GridSearchCV(estimator=clf, param_grid=dict(C=Cs))
cv_clf.fit(x_train, y_train)

x_val = np.load("${X_TEST}")
x_val = x_val[:, selected_features]
y_pred = cv_clf.predict(x_val)
np.save('y_pred.npy', y_pred)