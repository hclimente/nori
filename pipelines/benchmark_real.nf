#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.x_train = 'x_train.npy'
params.x_test = 'x_test.npy'
params.y_train = 'y_train.npy'
params.y_test = 'y_test.npy'
params.featnames = 'featnames.npy'

x_train = file(params.x_train)
x_test = file(params.x_test)
y_train = file(params.y_train)
y_test = file(params.y_test)
featnames = file(params.featnames)

params.mode = 'regression'
svm = (params.mode == 'regression')? 'SVR' : 'SVC'
stat = (params.mode == 'regression')? 'mse' : 'accuracy'
linmod = (params.mode == 'regression')? 'Lasso' : 'LogisticRegression'

params.B = [0, 20, 50]
params.causal = [10, 50, 100]

bins = file("$params.projectdir/pipelines/scripts")
binHSICLasso = file("$bins/methods/hsic_lasso.nf")
binLinear = file("$bins/methods/linear_classifier.nf")
binmRMR = file("$bins/methods/mrmr.nf")
binKernelSVM = file("$bins/methods/kernel_svm.nf")
binEvaluatePredictions = file("$bins/analysis/evaluate_predictions.nf")

process run_HSIC_lasso {

  errorStrategy 'ignore'

  input:
    file binHSICLasso
    file binKernelSVM
    file binEvaluatePredictions
    each B from params.B
    each c from params.causal
    file x_train
    file x_test
    file y_train
    file y_test
    file featnames

  output:
    file 'prediction_stats' into predictions_hsic

  """
  nextflow run $binHSICLasso --x $x_train --y $y_train --featnames $featnames --B $B --mode $params.mode --causal $c -profile bigmem
  nextflow run $binKernelSVM --x_train $x_train --y_train $y_train --x_test $x_test --selected_features features.npy --model $svm -profile cluster
  nextflow run $binEvaluatePredictions --y_test $y_test --predictions predictions.npy --stat $stat --n None --d None --causal $c --i None --model 'hsic_lasso-b$B' -profile cluster
  """

}

process run_linear_model {

  input:
    file binLinear
    file binEvaluatePredictions
    file x_train
    file x_test
    file y_train
    file y_test
    file featnames

  output:
    file 'prediction_stats' into predictions_lasso

  """
  nextflow run $binLinear --x_train $x_train --y_train $y_train --x_test $x_test --linmod $linmod --featnames $featnames -profile bigmem
  nextflow run $binEvaluatePredictions --y_test $y_test --predictions predictions.npy --stat $stat --n None --d None --causal None --i None --model $linmod -profile cluster
  """

}

process run_mRMR {

  input:
    file binmRMR
    file binKernelSVM
    file binEvaluatePredictions
    each c from params.causal
    file x_train
    file x_test
    file y_train
    file y_test

  output:
    file 'prediction_stats' into predictions_mrmr

  """
  nextflow run $binmRMR --x $x_train --y $y_train --featnames $featnames --causal $c -profile bigmem
  nextflow run $binKernelSVM --x_train $x_train --y_train $y_train --x_test $x_test --selected_features features.npy --model $svm -profile cluster
  nextflow run $binEvaluatePredictions --y_test $y_test --predictions predictions.npy --stat $stat --n None --d None --causal $c --i None --model 'mRMR' -profile cluster
  """

}

predictions = predictions_hsic. mix( predictions_lasso, predictions_mrmr )

process benchmark {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file "prediction_stats*" from predictions. collect()

  output:
    file 'prediction.tsv'

  """
  echo 'model\tn\td\ti\tc\t$stat' >prediction.tsv
  cat prediction_stats* >>prediction.tsv
  """

}
