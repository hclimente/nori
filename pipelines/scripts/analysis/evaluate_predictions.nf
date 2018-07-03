params.out = '.'

predictions = file("$params.predictions")
y_test = file("$params.y_test")

if (params.stat == 'accuracy') {

  process evaluate_classification {

    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
      file predictions
      file y_test

    output:
      file 'prediction_stats' into prediction_stats

    """
    #!/usr/bin/env python

    import csv
    import numpy as np
    from sklearn.metrics import accuracy_score

    y_true = np.load('$y_test').squeeze()
    y_pred = np.load('$predictions')

    accuracy = accuracy_score(y_true, y_pred)
    row = ['$params.model', $params.n, $params.d, $params.i,
           $params.causal, accuracy ]

    with open('prediction_stats', 'w', newline='') as f_output:
        tsv_output = csv.writer(f_output, delimiter='\t')
        tsv_output.writerow(row)
    """

  }
} else {

  process evaluate_regression {

    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
      file predictions
      file y_test

    output:
      file 'prediction_stats' into prediction_stats

    """
    #!/usr/bin/env python

    import csv
    import numpy as np
    from sklearn.metrics import mean_squared_error

    y_true = np.load('$y_test').squeeze()
    y_pred = np.load('$predictions')

    mse = mean_squared_error(y_true, y_pred, multioutput = 'uniform_average')
    row = ['$params.model', $params.n, $params.d, $params.i,
           $params.causal, mse ]

    with open('prediction_stats', 'w', newline='') as f_output:
        tsv_output = csv.writer(f_output, delimiter='\t')
        tsv_output.writerow(row)
    """

  }
}
