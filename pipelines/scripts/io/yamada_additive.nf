#!/usr/bin/env nextflow

params.out = "."

process generate_data {

  publishDir "$params.out", overwrite: true, mode: "copy"

  output:
    file 'x_train.npy'
    file 'y_train.npy'
    file 'x_val.npy'
    file 'y_val.npy'
    file 'featnames.npy'

  """
  #!/usr/bin/env python

  import numpy as np

  def additive(x1, x2, x3, x4):
    e = np.random.normal(size = x1.shape)
    return - 2*np.sin(2*x1) + np.square(x2) + x3 + np.exp(-x4) + e

  x_train = np.random.rand($params.d, $params.n)
  x_val = np.random.rand($params.d, 100)

  y_train = additive(x_train[0,:], x_train[1,:], x_train[2,:], x_train[3,:])
  y_train = np.expand_dims(y_train, 0)
  y_val = additive(x_val[0,:], x_val[1,:], x_val[2,:], x_val[3,:])
  y_val = np.expand_dims(y_val, 0)

  featnames = [ str(x) for x in np.arange($params.d) ]

  np.save("x_train.npy", x_train)
  np.save("y_train.npy", y_train)
  np.save("x_val.npy", x_val)
  np.save("y_val.npy", y_val)
  np.save("featnames.npy", featnames)
  """

}
