#!/usr/bin/env nextflow

params.out = "."

X = file(params.x)
Y = file(params.y)
featnames = file(params.featnames)

process run_HSIC_lasso {

  publishDir "$params.out", overwrite: true, mode: "copy"

  beforeScript 'echo -e "import numpy as np\\nnp.save(\'features.npy\', np.array([]))" | python'
  validExitStatus 0,1,137,140

  input:
    file X
    file Y
    file featnames

  output:
    file 'features.npy'

  """
  #!/usr/bin/env python

  import numpy as np
  from pyHSICLasso import HSICLasso

  hl = HSICLasso()

  hl.X_in = np.load("$X")
  hl.Y_in = np.load("$Y")
  hl.featname = np.load("$featnames")

  d,n = hl.X_in.shape

  if $params.B:
    discard = np.random.choice(np.arange(n), n % $params.B, replace = False)
    hl.X_in = np.delete(hl.X_in, discard, 1)
    hl.Y_in = np.delete(hl.Y_in, discard, 1)

  hl.$params.mode($params.causal, B = $params.B)
  np.save('features.npy', hl.A)
  """

}