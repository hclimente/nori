#!/usr/bin/env nextflow

params.out = "."

n = params.n
d = params.d

process generate_data {

  publishDir "$params.out", overwrite: true, mode: "copy"

  output:
    file "*.npy" into npy

  """
  #!/usr/bin/env python

  import numpy as np

  X = np.random.rand($d, $n)
  Y = np.square(X[0,:]) + np.power(X[1,:], 3) + np.sin(X[2,:]) + 3 * np.cos(X[3,:]) + np.log(X[4,:])
  Y = np.expand_dims(Y, 0)
  featname = [ str(x) for x in np.arange($d) ]

  np.save("X.npy", X)
  np.save("Y.npy", Y)
  np.save("snps.npy", featname)
  """

}
