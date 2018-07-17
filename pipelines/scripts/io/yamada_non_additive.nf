#!/usr/bin/env nextflow

params.out = "."

datasets = ['train', 'val']
N = [params.n, 100]

process generate_data {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    val sets from datasets
    val n from N

  output:
    file "x_${sets}.npy"
    file "y_${sets}.npy"

  """
  #!/usr/bin/env python

  import numpy as np

  def non_additive(x1, x2, x3):
    e = np.random.normal(size = x1.shape)
    return x1 * np.exp(2*x2) + np.square(x3) + e

  x = np.random.rand($params.d, $n)
  y = non_additive(x[0,:], x[1,:], x[2,:], x[3,:])

  np.save("x_${sets}.npy", x)
  np.save("y_${sets}.npy", y)
  """

}

process get_features {

  publishDir "$params.out", overwrite: true, mode: "copy"

  output:
    file 'featnames.npy'

    """
    #!/usr/bin/env python

    import numpy as np

    featnames = [ str(x) for x in np.arange($params.d) ]

    np.save("featnames.npy", featnames)
    """

}
