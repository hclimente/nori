params.out = '.'

X = file(params.X)
Y = file(params.Y)
X_test = file(params.X_test)
selected_features = file(params.selected_features)
model = params.model

process predict {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y
    file selected_features
    file X_test

  output:
    file 'predictions'

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn import svm

  selected_features = np.loadtxt("$selected_features", dtype='int')
  X = np.load("$X").T
  X = X[:, selected_features]
  Y = np.load("$Y").squeeze()

  clf = svm.$model()
  clf.fit(X, Y)

  X_test = np.load("$X_test").T
  X_test = X_test[:, selected_features]
  predictions = clf.predict(X_test)
  np.savetxt('predictions', predictions)
  """

}
