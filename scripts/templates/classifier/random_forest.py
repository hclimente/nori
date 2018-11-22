#!/usr/bin/env python
'''
Input variables:
    - SELECTED_FEATURES: path to the selected features.
    - X_TRAIN: path to numpy array with train X matrix.
    - Y_TRAIN: path to numpy array with train Y vector.
    - X_TEST: path to numpy array with validation X matrix.
    - C: number of causal features.
Output files:
    - y_pred.npy
'''

import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV

selected_features = np.load("${SELECTED_FEATURES}")
x_train = np.load("${X_TRAIN}")
y_train = np.load("${Y_TRAIN}")
x_test = np.load("${X_TEST}")

# filter matrix by extracted features
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

clf = RandomForestClassifier()

param_grid = { 
    'n_estimators': [200, 500],
    'max_features': ['auto', 'log2'],
    'max_depth' : [4,6,8],
    'criterion' :['gini', 'entropy']
}

cv_clf = GridSearchCV(clf, param_grid)
cv_clf.fit(x_train, y_train)

y_pred = cv_clf.predict(x_test)
np.save('y_pred.npy', y_pred)
