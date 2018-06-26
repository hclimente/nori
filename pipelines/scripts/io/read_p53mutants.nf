#!/usr/bin/env nextflow

params.out = "."

data = file("$params.data")

process preprocess {

  input:
    file data

  output:
    file 'data.csv' into csv

  """
  sed 's/,\$//' $data >data.csv
  """

}

process read_p53mutants {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file csv

  output:
    file "X.npy" into X
    file "Y.npy" into Y
    file "featnames.npy" into featnames

    """
    #!/usr/bin/env python

    import numpy as np
    import pandas as pd

    mutants = pd.read_csv("$csv", header = None, low_memory = False)

    # encode protein active-status as 0/1
    Y = mutants.iloc[:,-1]
    Y = pd.factorize(Y)[0]
    Y = np.expand_dims(Y, 0)

    # encode matrix as float
    mutants.drop(mutants.columns[[-1]], axis=1, inplace=True)
    X = mutants.values
    X[X == '?'] = 'nan'
    X = X.astype('float')
    X = X.T

    # feature names as numbered strings
    featnames = [ str(x) for x in mutants.columns.values ]

    # remove samples with many nans
    badfeats = np.sum(np.isnan(X), axis = 0) > 0
    X = X[:, np.logical_not(badfeats)]

    np.save("X.npy", X)
    np.save("Y.npy", Y)
    np.save("featnames.npy", featnames)
    """

}
