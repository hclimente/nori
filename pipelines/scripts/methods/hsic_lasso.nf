#!/usr/bin/env nextflow

params.out = "."

X = file(params.X)
Y = file(params.Y)
snps = file(params.snps)

process run_HSIC_lasso {

  input:
    file X
    file Y
    file snps

  output:
    file 'aggregated_score.csv' into aggregated_score
    file 'param.csv' into parameters

  """
  #!/usr/bin/env python

  import numpy as np
  from pyHSICLasso import HSICLasso

  hl = HSICLasso()

  hl.X_in = np.load("$X")
  hl.Y_in = np.load("$Y")
  hl.featname = np.load("$snps")

  d,n = hl.X_in.shape

  if $params.B:
    discard = np.random.choice(np.arange(10), n % $params.B, replace = False)
    hl.X_in = np.delete(hl.X_in, discard, 1)
    hl.Y_in = np.delete(hl.Y_in, discard, 1)

  hl.$params.mode($params.causal, B = $params.B)

  hl.save_score()
  hl.save_param()
  """

}

process standarize_output {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file aggregated_score
    file parameters

  output:
    file 'features' into features

  """
  #!/usr/bin/env Rscript

  library(tidyverse)

  scores <- read_csv("$aggregated_score", col_types = 'cdd')
  parameters <- read_csv("$parameters", col_types = 'cdcdcdcdcdcdcdcdcdcdcd')

  select(parameters, Feature) %>%
    write_tsv('features', col_names = FALSE)
  """

}
