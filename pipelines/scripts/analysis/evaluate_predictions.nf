params.out = '.'

params.outcome = 'numerical'

predictions = file("$params.predictions")
Y = file("$params.y")
outcome = params.outcome

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
