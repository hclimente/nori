#!/usr/bin/env nextflow

params.out = "."

params.causal = 5

process generate_data {

  publishDir "$params.out", overwrite: true, mode: "copy"

  output:
    file "*.npy" into npy
    stdout equation

  """
  #!/usr/bin/env python

  import numpy as np

  X_train = 10 * np.random.rand($params.d, $params.n)
  X_test = 10 * np.random.rand($params.d, 100)

  F = [(np.power, [4]), (np.power, [5]), (np.power, [6]),
       (np.log, None), (np.sin, None), (np.cos, None)]
  funs = np.random.choice(np.arange(len(F)), $params.causal)

  Y_train = np.zeros((1, $params.n))
  Y_test = np.zeros((1, 100))

  print('Y = 0', end='')
  for i in range($params.causal):
    f,args = F[funs[i]]
    print(' + {}(X[{},],{})'.format(f.__name__, i, args), end='')
    y_train = f(X_train[i,:], args)
    y_test = f(X_test[i,:], args)
    # normalize by the variance
    Y_train += (y_train - min(y_train))/(max(y_train) - min(y_train))
    Y_test += (y_test - min(y_test))/(max(y_test) - min(y_test))

  featnames = [ str(x) for x in np.arange($params.d) ]

  np.save("X_train.npy", X_train)
  np.save("Y_train.npy", Y_train)
  np.save("X_test.npy", X_test)
  np.save("Y_test.npy", Y_test)
  np.save("featnames.npy", featnames)
  """

}

equation .subscribe { println it }
