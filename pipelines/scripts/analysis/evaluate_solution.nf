params.out = '.'

params.outcome = 'numerical'

features = file("$params.features")
predictions = file("$params.predictions")
Y = file("$params.y")
outcome = params.outcome

if (params.features) {

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
}

if (predictions) {

  if (outcome == 'categorical') {

    process evaluate_classification {

      publishDir "$params.out", overwrite: true, mode: "copy"

      input:
        file predictions
        file Y

      output:
        file 'prediction_stats' into prediction_stats

      """
      #!/usr/bin/env Rscript
      library(tidyverse)
      library(RcppCNPy)

      predictions <- read_tsv("$predictions", col_names = FALSE, col_types = 'd')\$X1
      Y <- npyLoad("$Y") %>% t
      p <- $params.causal
      n <- $params.d - $params.causal
      tpr <- sum(predictions == Y) / p
      fpr <- sum(predictions != Y) / n

      data_frame(model = "$params.model", n = "$params.n",
                 d = "$params.d", i = "$params.i",
                 c = "$params.causal",
                 tpr = as.numeric(tpr), fpr = as.numeric(fpr) ) %>%
        write_tsv("prediction_stats", col_names = FALSE)
      """

    }
  } else {

    process evaluate_regression {

      publishDir "$params.out", overwrite: true, mode: "copy"

      input:
        file predictions
        file Y

      output:
        file 'prediction_stats' into prediction_stats

      """
      #!/usr/bin/env Rscript
      library(tidyverse)
      library(RcppCNPy)

      predictions <- read_tsv("$predictions", col_names = FALSE, col_types = 'd')\$X1
      Y <- npyLoad("$Y") %>% t
      r2 <- cor(predictions, Y) ^ 2

      data_frame(model = "$params.model", n = "$params.n",
                 d = "$params.d", i = "$params.i",
                 c = "$params.causal", r2 = as.numeric(r2)) %>%
        write_tsv("prediction_stats", col_names = FALSE)
      """

    }
  }

}
