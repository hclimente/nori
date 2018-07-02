params.out = '.'

features = file("$params.features")

process evaluate_features {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file features

  output:
    file 'feature_stats' into feature_stats

  """
  #!/usr/bin/env Rscript
  library(tidyverse)

  features <- read_tsv("$features", col_types = 'i', col_names = FALSE)
  tp <- intersect(seq(1, $params.causal), features\$X1) %>% length
  p <- $params.causal
  fp <- setdiff(seq(1, $params.causal), features\$X1) %>% length
  n <- $params.d - $params.causal
  tpr <- length(tp) / p
  fpr <- length(fp) / n

  data_frame(model = "$params.model", n = "$params.n",
             d = "$params.d", i = "$params.i",
             c = "$params.causal", tpr = tpr, fpr = fpr) %>%
    write_tsv("feature_stats", col_names = FALSE)
  """

}
