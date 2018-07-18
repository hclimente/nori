#!/usr/bin/env nextflow

params.out = "."

features = file(params.selected_features)

process filter_features {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file features

  output:
    file "filtered_features.npy"

  """
  #!/usr/bin/env python

  import numpy as np

  features = np.load('$features')
  filtered_features = features[0:$params.n]

  np.save("filtered_features.npy", filtered_features)
  """

}
