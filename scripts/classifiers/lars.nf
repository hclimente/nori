#!/usr/bin/env nextflow

params.out = "."

x_train = file(params.x_train)
y_train = file(params.y_train)
x_val = file(params.x_val)

process predict {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file x_train
    file y_train
    file x_val

  output:
    file 'features.npy' into features
    file 'predictions.npy' into predictions

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn.linear_model import Lars
  from sklearn.feature_selection import SelectFromModel

  x_train = np.load('$x_train').T
  y_train = np.load('$y_train').squeeze()

  clf = Lars(n_nonzero_coefs = $params.select)
  clf.fit(x_train, y_train)

  x_val = np.load('$x_val').T
  y_pred = clf.predict(x_val)
  np.save('predictions.npy', y_pred)

  sfm = SelectFromModel(clf, prefit = True)
  features = np.where(sfm.get_support())[0]
  np.save('features.npy', features)
  """

}
