params.out = '.'

X = file("$params.x")
Y = file("$params.y")

params.split = 0.1

process split {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file X
    file Y

  output:
    file 'x_train.npy'
    file 'x_test.npy'
    file 'y_train.npy'
    file 'y_test.npy'

  """
  #!/usr/bin/env python

  import numpy as np
  from sklearn.model_selection import train_test_split

  X = np.load("$X").T
  Y = np.load("$Y").T

  x_train, x_test, y_train, y_test = train_test_split(X, Y,
                                  test_size = $params.split, random_state = 42)

  np.save("x_train.npy", x_train.T)
  np.save("x_test.npy", x_test.T)
  np.save("y_train.npy", y_train.T)
  np.save("y_test.npy", y_test.T)
  """

}
