params.out = '.'

x_train = file(params.x_train)
y_train = file(params.y_train)
x_val = file(params.x_val)
selected_features = file(params.selected_features)
model = params.model

process predict {

  beforeScript 'echo -e "import numpy as np\\nnp.save(\'predictions.npy\', np.array([]))" | python'
  validExitStatus 0,99

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file x_train
    file y_train
    file selected_features
    file x_val

  output:
    file 'predictions.npy'

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn import svm
  from sklearn.model_selection import GridSearchCV

  selected_features = np.load("$selected_features")
  x_train = np.load("$x_train").T

  try:
    x_train = x_train[:, selected_features]
  except ValueError:
    import sys, traceback
    traceback.print_exc()
    sys.exit(99)

  y_train = np.load("$y_train").squeeze()

  clf = svm.$model()

  Cs = np.logspace(-6, 1, 10)
  clf = GridSearchCV(estimator=clf, param_grid=dict(C=Cs))
  clf.fit(x_train, y_train)

  x_val = np.load("$x_val").T
  x_val = x_val[:, selected_features]
  predictions = clf.predict(x_val)
  np.save('predictions.npy', predictions)
  """

}
