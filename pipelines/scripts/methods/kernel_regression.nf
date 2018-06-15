params.out = '.'

X = file("$params.X")
Y = file("$params.Y")
selected_features = file("$params.selected_features")

process regression {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y
    file selected_features

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

  clf = svm.SVR()
  clf.fit(X, Y)

  predictions = clf.predict(X)
  np.savetxt('predictions', predictions)
  """

}
