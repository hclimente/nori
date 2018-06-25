#!/usr/bin/env nextflow

params.out = "."

params.causal = 5

process generate_data {

  publishDir "$params.out", overwrite: true, mode: "copy"

  output:
    file "*.npy" into npy

  """
  #!/usr/bin/env python

  import numpy as np

  X_train = np.random.rand($params.d, $params.n)
  X_test = np.random.rand($params.d, 100)

  F = [(np.square, None), (np.power, [3]), (np.power, [4]),
       (np.power, [5]), (np.power, [6]), (np.log, None),
       (np.sin, None), (np.cos, None)]
  funs = np.random.choice(np.arange(len(F)), $params.causal)

  Y_train = np.zeros((1, $params.n))
  Y_test = np.zeros((1, 100))
  for i in range($params.causal):
    f,args = F[funs[i]]
    y_train = f(X_train[i,:], args)
    y_test = f(X_test[i,:], args)
    # normalize by the variance
    Y_train += y_train / np.var(y_train)
    Y_test += y_test / np.var(y_test)

  featnames = [ str(x) for x in np.arange($params.d) ]

  np.save("X_train.npy", X_train)
  np.save("Y_train.npy", Y_train)
  np.save("X_test.npy", X_test)
  np.save("Y_test.npy", Y_test)
  np.save("featnames.npy", featnames)
  """

}
