#!/usr/bin/env nextflow

params.out = "."

X = file(params.x)
Y = file(params.y)

process prepare_csv {

  input:
    file X
    file Y

  output:
    file 'dataset.csv' into csv


  """
  #!/usr/bin/env python

  import numpy as np

  X = np.load("$X")
  Y = np.load("$Y")

  np.savetxt('dataset.csv', np.vstack((Y,X)).T,
             header = 'y,' + ','.join([ str(x) for x in np.arange(X.shape[0])]),
             delimiter = ',', comments='')
  """

}

process run_mRMR {

  input:
    file csv

  output:
    file 'features' into features

  """
  mrmr -i $csv -t 0 -n $params.causal -s `wc -l $csv` -v `head -n1 $csv | sed 's/,/\\n/g' | wc -l` >results
  grep -A `expr $params.causal + 1` mRMR results | head -n `expr $params.causal + 2` | tail -n $params.causal | cut -f3 | sed 's/ //g' >features
  """

}

process tsv2npy {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file features

  output:
    file 'features.npy'

  """
  #!/usr/bin/env python

  import numpy as np

  feats_pred = np.loadtxt('$features', dtype = 'uint8')
  np.save('features.npy', feats_pred)
  """

}
