#!/usr/bin/env nextflow

params.out = "."

X = file(params.X)
Y = file(params.Y)

process run_lasso {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y

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

  predictions = clf.predict(X)
  np.savetxt('predictions', predictions)

  features = np.where(clf.coef_ != 0)
  np.savetxt('features', features)
  """

}
