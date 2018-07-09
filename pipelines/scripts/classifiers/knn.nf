params.out = '.'

x_train = file(params.x_train)
y_train = file(params.y_train)
x_val = file(params.x_val)
selected_features = file(params.selected_features)
model = params.model

process predict {

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
  from sklearn.neighbors import KNeighborsClassifier
  from sklearn.model_selection import GridSearchCV

  selected_features = np.load("$selected_features")
  x_train = np.load("$x_train").T
  x_train = x_train[:, selected_features]
  y_train = np.load("$y_train").squeeze()

  clf = KNeighborsClassifier()
  clf.fit(x_train, y_train)

  x_val = np.load("$x_val").T
  x_val = x_val[:, selected_features]
  predictions = clf.predict(x_val)
  np.save('predictions.npy', predictions)
  """

}
