#!/usr/bin/env python

import numpy as np
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import GridSearchCV

selected_features = np.load("$selected_features")
x_train = np.load("$x_train").T

try:
    if not selected_features.any():
        raise IndexError('No selected features')
    x_train = x_train[:, selected_features]
except IndexError:
    import sys, traceback
    traceback.print_exc()
    sys.exit(77)

y_train = np.load("$y_train").squeeze()

clf = KNeighborsClassifier()
clf.fit(x_train, y_train)

x_val = np.load("$x_val").T
x_val = x_val[:, selected_features]
predictions = clf.predict(x_val)
np.save('predictions.npy', predictions)