#!/usr/bin/env nextflow

params.out = "."

discretization = (params.mode == 'regression')? '-t 0' : ''

x = file(params.x)
y = file(params.y)

process prepare_csv {

  input:
    file x
    file y

  output:
    file 'dataset.csv' into csv


  """
  #!/usr/bin/env python

  import numpy as np

  x = np.load("$x")
  y = np.load("$y")

  np.savetxt('dataset.csv', np.vstack((y,x)).T,
             header = 'y,' + ','.join([ str(x) for x in np.arange(x.shape[0])]),
             delimiter = ',', comments='')
  """

}

process run_mRMR {

  beforeScript 'touch features'
  validExitStatus 0,134,140

  input:
    file csv

  output:
    file 'features' into features

  """
  samples=`cat $csv | wc -l | sed 's/ \\+//'`
  features=`head -n1 $csv | sed 's/,/\\n/g' | wc -l | sed 's/ \\+//'`
  mrmr -i $csv $discretization -n $params.causal -s \$samples -v \$features >results
  grep -A `expr $params.causal + 1` mRMR results | head -n `expr $params.causal + 2` | tail -n $params.causal | cut -f3 | sed 's/ //g' | grep -v "[a-z]" >features
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
