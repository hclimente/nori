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

  X = np.random.rand($params.d, $params.n)

  F = [(np.square, None), (np.power, [3]), (np.power, [4]),
       (np.power, [5]), (np.power, [6]), (np.log, None),
       (np.sin, None), (np.cos, None)]
  funs = np.random.choice(np.arange(len(F)), $params.causal)

  Y = np.zeros((1, $params.n))
  for i in range($params.causal):
    f,args = F[funs[i]]
    Y += f(X[i,:], args)

  featname = [ str(x) for x in np.arange($params.d) ]

  np.save("X.npy", X)
  np.save("Y.npy", Y)
  np.save("snps.npy", featname)
  """

}
