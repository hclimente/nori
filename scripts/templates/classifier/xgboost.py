#!/usr/bin/env python
'''
Input variables:
    - SELECTED_FEATURES: path to the selected features.
    - X_TRAIN: path to numpy array with train X matrix.
    - Y_TRAIN: path to numpy array with train Y vector.
    - X_TEST: path to numpy array with test X matrix.
    - Y_TEST: path to numpy array with test Y vector.
    - C: number of causal features.
Output files:
    - y_pred.npy
'''

import numpy as np
import xgboost as xgb
from sklearn.model_selection import cross_val_score

selected_features = np.load("${SELECTED_FEATURES}")
x_train = np.load("${X_TRAIN}")
x_test = np.load("${X_TEST}")
y_train = np.load("${Y_TRAIN}")
y_train -= 1

# select features
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

# get number of classes
y_test = np.load("${Y_TRAIN}")
y_test -= 1
y = np.concatenate((y_train, y_test))

num_classes = len(np.unique(y))

# cv eta values
cv_scores = []
etas = [.3, .2, .1, .05, .01, .005]

for e in etas:
    clf = xgb.XGBClassifier(learning_rate = e, objective = 'multi:softmax', num_class = num_classes)
    scores = cross_val_score(clf, x_train, y_train, cv = 3, scoring='accuracy')
    cv_scores.append(scores.mean())

# build model and predict
best_eta = etas[np.argmax(cv_scores)]
clf = xgb.XGBClassifier(learning_rate = best_eta, objective = 'multi:softmax', num_class = num_classes)
clf.fit(x_train, y_train)

y_pred = clf.predict(x_test) + 1
np.save('y_pred.npy', y_pred)


