params.out = '.'

x_train = file(params.x_train)
y_train = file(params.y_train)
x_test = file(params.x_test)
selected_features = file(params.selected_features)
model = params.model

process predict {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file x_train
    file y_train
    file selected_features
    file x_test

  output:
    file 'predictions.npy'

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn import svm

  selected_features = np.load("$selected_features")
  x_train = np.load("$x_train").T
  x_train = x_train[:, selected_features]
  y_train = np.load("$y_train").squeeze()

  clf = svm.$model()
  clf.fit(x_train, y_train)

  x_test = np.load("$x_test").T
  x_test = x_test[:, selected_features]
  predictions = clf.predict(x_test)
  np.save('predictions.npy', predictions)
  """

}
