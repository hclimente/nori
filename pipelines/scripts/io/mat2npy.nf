#!/usr/bin/env nextflow

params.out = "."

mat = file(params.mat)

process mat2npy {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file mat

  output:
    file "*.npy"

  """
  #!/usr/bin/env python

  import numpy as np
  from scipy import io as spio

  data = spio.loadmat("$mat")

  x = data["X"].T
  y = data["Y"].T

  d = x.shape[0]
  featname = [('%d' % i) for i in range(1,d+1)]

  np.save("x.npy", x)
  np.save("y.npy", y)
  np.save("featnames.npy", featname)
  """

}
