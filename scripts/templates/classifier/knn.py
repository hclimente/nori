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
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import cross_val_score

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

# cv best number of neighbors
K = range(1, 11, 2)
cv_scores = []

for k in K:
    knn = KNeighborsClassifier(n_neighbors = k, weights = 'distance')
    scores = cross_val_score(knn, x_train, y_train, cv = 3, scoring='accuracy')
    cv_scores.append(scores.mean())

best_k = K[np.argmax(cv_scores)]

# build model and predict
clf = KNeighborsClassifier(n_neighbors = best_k, weights = 'distance')
clf.fit(x_train, y_train)

y_pred = clf.predict(x_test)
np.save('y_pred.npy', y_pred)
