params.out = '.'

features = file("$params.features")
predictions = file("$params.predictions")
y_val = file("$params.y_val")

process evaluate_classification {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file features
    file predictions
    file y_val

  output:
    file 'prediction_stats' into prediction_stats

  """
  #!/usr/bin/env python

  import csv
  import numpy as np
  from sklearn.metrics import accuracy_score, mean_squared_error

  y_true = np.load('$y_val').squeeze()
  y_pred = np.load('$predictions')
  feats_pred = np.load('$features')

  score = np.nan
  if len(y_pred):
    if '$params.stat' == 'accuracy':
      score = accuracy_score(y_true, y_pred)
    else:
      score = mean_squared_error(y_true, y_pred, multioutput = 'uniform_average')

  row = ['$params.model', $params.n, $params.d, $params.causal,
         len(feats_pred), $params.i, score ]

  with open('prediction_stats', 'w', newline='') as f_output:
      tsv_output = csv.writer(f_output, delimiter='\t')
      tsv_output.writerow(row)
  """

}
