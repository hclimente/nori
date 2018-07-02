params.out = '.'

X = file("$params.X")
Y = file("$params.Y")

params.split = 0.1

process split {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y

  output:
    file 'X_train.npy'
    file 'X_test.npy'
    file 'Y_train.npy'
    file 'Y_test.npy'

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn.model_selection import train_test_split

  X = np.load("$X").T
  Y = np.load("$Y").T

  X_train, X_test, Y_train, Y_test = train_test_split(X, Y,
                                  test_size = $params.split, random_state = 42)

  np.save("X_train.npy", X_train.T)
  np.save("X_test.npy", X_test.T)
  np.save("Y_train.npy", Y_train.T)
  np.save("Y_test.npy", Y_test.T)
  """

}
