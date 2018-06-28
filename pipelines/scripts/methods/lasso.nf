#!/usr/bin/env nextflow

params.out = "."

X = file(params.X)
Y = file(params.Y)
X_test = file(params.X_test)

process run_lasso {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y
    file X_test

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

  X_test = np.load("$X_test").T
  predictions = clf.predict(X_test)
  np.savetxt('predictions', predictions)

  features = np.nonzero(clf.coef_)[0] 
  np.savetxt('features', features, fmt = '%i')
  """

}
