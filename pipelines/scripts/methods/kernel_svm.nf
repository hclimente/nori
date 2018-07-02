params.out = '.'

X = file(params.x)
Y = file(params.y)
x_test = file(params.x_test)
selected_features = file(params.selected_features)
model = params.model

process predict {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y
    file selected_features
    file x_test

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

  x_test = np.load("$x_test").T
  x_test = x_test[:, selected_features]
  predictions = clf.predict(x_test)
  np.savetxt('predictions', predictions)
  """

}
