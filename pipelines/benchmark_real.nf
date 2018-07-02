#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.x_train = 'X_train.npy'
params.x_test = 'X_test.npy'
params.y_train = 'Y_train.npy'
params.y_test = 'Y_test.npy'
params.featnames = 'featnames.npy'

x_train = file(params.x_train)
x_test = file(params.x_test)
y_train = file(params.y_train)
y_test = file(params.y_test)
featnames = file(params.featnames)

params.mode = 'regression'
svm = (params.mode == 'regression')? 'SVR' : 'SVC'

params.B = [0, 20, 50]
params.causal = [10, 50, 100]

bins = file("$params.projectdir/pipelines/scripts")
binHSICLasso = file("$bins/methods/hsic_lasso.nf")
binLasso = file("$bins/methods/lasso.nf")
binmRMR = file("$bins/methods/mrmr.nf")
binKernelSVM = file("$bins/methods/kernel_svm.nf")
binEvaluateSolution = file("$bins/analysis/evaluate_solution.nf")

process run_HSIC_lasso {

  errorStrategy 'ignore'

  input:
    file binHSICLasso
    file binEvaluateSolution
    each B from params.B
    each c from params.causal
    file x_train
    file x_test
    file y_train
    file y_test
    file featnames

  output:
    file 'feature_stats' into features_hsic
    file 'prediction_stats' into predictions_hsic

  """
  nextflow run $binHSICLasso --X $x_train --Y $y_train --featnames featnames.npy --B $B --mode $params.mode --causal $c -profile bigmem
  nextflow run $binKernelSVM --X $x_train --Y $y_train --x_test $x_test --selected_features features --model $svm -profile cluster
  nextflow run $binEvaluateSolution --features features --Y $y_test --predictions predictions --n - --d - --causal $c --i - --model 'hsic_lasso-b$B' -profile cluster
  """

}

process run_lasso {

  input:
    file binLasso
    file binEvaluateSolution
    file x_train
    file x_test
    file y_train
    file y_test

  output:
    file 'feature_stats' into features_lasso
    file 'prediction_stats' into predictions_lasso

  """
  nextflow run $binLasso --X $x_train --Y $y_train --x_test $x_test --featnames featnames.npy -profile bigmem
  nextflow run $binEvaluateSolution --features features --Y $y_test --predictions predictions --n - --d - --causal - --i - --model 'lasso' -profile cluster
  """

}

process run_mRMR {

  input:
    file binmRMR
    file binEvaluateSolution
    each c from params.causal
    file x_train
    file x_test
    file y_train
    file y_test

  output:
    file 'feature_stats' into features_mrmr
    file 'prediction_stats' into predictions_mrmr

  """
  nextflow run $binmRMR --X $x_train --Y $y_train --featnames featnames.npy --causal $c -profile bigmem
  nextflow run $binKernelSVM --X $x_train --Y $y_train --x_test $x_test --selected_features features --model $svm -profile cluster
  nextflow run $binEvaluateSolution --features features --Y $y_test --predictions predictions --n - --d - --causal $c --i - --model 'mRMR' -profile cluster
  """

}

features = features_hsic. mix( features_lasso, features_mrmr )
predictions = predictions_hsic. mix( predictions_lasso, predictions_mrmr )

process benchmark {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file "feature_stats*" from features. collect()
    file "prediction_stats*" from predictions. collect()

  output:
    file 'feature_selection.tsv'
    file 'prediction.tsv'

  """
  echo 'model\tn\td\ti\tc\ttpr\tfpr' >feature_selection.tsv
  cat feature_stats* >>feature_selection.tsv

  echo 'model\tn\td\ti\tc\tr2' >prediction.tsv
  cat prediction_stats* >>prediction.tsv
  """

}
