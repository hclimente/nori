#!/usr/bin/env nextflow

params.out = "."

x_train = file(params.x_train)
y_train = file(params.y_train)
x_test = file(params.x_test)

params.linmod = 'Lasso'

process predict {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file x_train
    file y_train
    file x_test

  output:
    file 'features.npy' into features
    file 'predictions.npy' into predictions

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn.linear_model import $params.linmod

  x_train = np.load("$x_train").T
  y_train = np.load("$y_train").squeeze()

  clf = $params.linmod()
  clf.fit(x_train, y_train)

  x_test = np.load("$x_test").T
  predictions = clf.predict(x_test)
  np.save('predictions.npy', predictions)

  features = np.nonzero(clf.coef_)[0]
  np.save('features.npy', features)
  """

}
