#!/usr/bin/env nextflow

params.out = "."

X = file(params.x)
Y = file(params.y)
x_test = file(params.x_test)

process run_lasso {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y
    file x_test

  output:
    file 'features' into features
    file 'predictions' into predictions

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn.linear_model import Lasso

  X = np.load("$X").T
  Y = np.load("$Y").squeeze()

  clf = Lasso()
  clf.fit(X, Y)

  x_test = np.load("$x_test").T
  predictions = clf.predict(x_test)
  np.savetxt('predictions', predictions)

  features = np.nonzero(clf.coef_)[0]
  np.savetxt('features', features, fmt = '%i')
  """

}
