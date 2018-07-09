params.out = '.'

x = file("$params.x")
y = file("$params.y")

params.split = 0.1

process split {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file x
    file y

  output:
    file 'x_train.npy'
    file 'x_val.npy'
    file 'y_train.npy'
    file 'y_val.npy'

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn.model_selection import train_test_split

  x = np.load("$x").T
  y = np.load("$y").T

  n = x.shape[0]
  perm = np.random.permutation(n)
  x = x[perm,:]
  y = y[perm,:]

  x_train, x_val, y_train, y_val = \
      train_test_split(x, y, test_size = $params.split)

  np.save("x_train.npy", x_train.T)
  np.save("x_val.npy", x_val.T)
  np.save("y_train.npy", y_train.T)
  np.save("y_val.npy", y_val.T)
  """

}
