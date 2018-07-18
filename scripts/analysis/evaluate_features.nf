params.out = '.'

features = file("$params.features")

process evaluate_features {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file features

  output:
    file 'feature_stats' into feature_stats

  """
  #!/usr/bin/env python

  import csv
  import numpy as np

  feats_true = np.arange($params.causal)
  feats_pred = np.load('$features')
  feats_top = feats_pred[0:$params.causal]

  tpr = np.nan
  if len(feats_top):
    tpr = len(np.intersect1d(feats_true, feats_top)) / len(feats_true)

  row = ['$params.model', $params.n, $params.d, $params.causal,
         len(feats_pred), $params.i, tpr ]

  with open('feature_stats', 'w', newline='') as f_output:
      tsv_output = csv.writer(f_output, delimiter='\t')
      tsv_output.writerow(row)
  """

}