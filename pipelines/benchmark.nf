#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.perms = 10
params.n = [100, 1000, 10000]
params.d = [1000, 2500, 5000, 10000]
params.B = [0, 20, 50]
params.causal = [10, 50, 100]

bins = file("${params.projectdir}/pipelines/scripts")
binSimulateData = file("$bins/io/generate_non-linear_data.nf")
binHSICLasso = file("$bins/methods/hsic_lasso.nf")
binLinear = file("$bins/methods/linear_classifier.nf")
binmRMR = file("$bins/methods/mrmr.nf")
binKernelSVM = file("$bins/methods/kernel_svm.nf")
binSimulateData = file("$bins/io/generate_non-linear_data.nf")
binEvaluatePredictions = file("$bins/analysis/evaluate_predictions.nf")
binEvaluateFeatures = file("$bins/analysis/evaluate_features.nf")

params.mode = 'regression'
svm = (params.mode == 'regression')? 'SVR' : 'SVC'
stat = (params.mode == 'regression')? 'mse' : 'accuracy'
linmod = (params.mode == 'regression')? 'Lasso' : 'LogisticRegression'

process simulate_data {

  input:
    each i from 1..params.perms
    each n from params.n
    each d from params.d
    each c from params.causal
    file binSimulateData

  output:
    set n,d,i,c,"x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" into data

  """
  nextflow run $binSimulateData --n $n --d $d --causal $c -profile cluster
  """

}

data.into { data_hsic; data_lasso; data_mrmr }

process run_HSIC_lasso {

  errorStrategy 'ignore'

  input:
    file binHSICLasso
    file binEvaluatePredictions
    file binEvaluateFeatures
    each B from params.B
    set n,d,i,c,"x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" from data_hsic

  output:
    file 'feature_stats' into features_hsic
    file 'prediction_stats' into predictions_hsic

  """
  nextflow run $binHSICLasso --x x_train.npy --y y_train.npy --featnames featnames.npy --B $B --mode regression --causal $c -profile bigmem
  nextflow run $binKernelSVM --x_train x_train.npy --y_train y_train.npy --x_test x_test.npy --selected_features features.npy --model $svm -profile cluster
  nextflow run $binEvaluatePredictions --y_test y_test.npy --stat $stat --predictions predictions.npy --n $n --d $d --causal $c --i $i --model 'hsic_lasso-b$B' -profile cluster
  nextflow run $binEvaluateFeatures --features features.npy --n $n --d $d --causal $c --i $i --model 'hsic_lasso-b$B' -profile cluster
  """

}

process run_linear_model {

  input:
    file binLinear
    file binEvaluatePredictions
    file binEvaluateFeatures
    set n,d,i,c,"x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" from data_lasso

  output:
    file 'feature_stats' into features_lasso
    file 'prediction_stats' into predictions_lasso

  """
  nextflow run $binLinear --x_train x_train.npy --y_train y_train.npy --x_test x_test.npy --linmod $linmod --featnames featnames.npy -profile bigmem
  nextflow run $binEvaluatePredictions --y_test y_test.npy --stat $stat --predictions predictions.npy --n $n --d $d --causal $c --i $i --model 'lasso' -profile cluster
  nextflow run $binEvaluateFeatures --features features.npy --n $n --d $d --causal $c --i $i --model $linmod -profile cluster
  """

}

process run_mRMR {

  input:
    file binmRMR
    file binEvaluatePredictions
    file binEvaluateFeatures
    set n,d,i,c,"x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" from data_mrmr

  output:
    file 'feature_stats' into features_mrmr
    file 'prediction_stats' into predictions_mrmr

  """
  nextflow run $binmRMR --x x_train.npy --y y_train.npy --featnames featnames.npy --causal $c -profile bigmem
  nextflow run $binKernelSVM --x_train x_train.npy --y_train y_train.npy --x_test x_test.npy --selected_features features.npy --model SVR -profile cluster
  nextflow run $binEvaluatePredictions --y_test y_test.npy --stat $stat --predictions predictions.npy --n $n --d $d --causal $c --i $i --model 'mRMR' -profile cluster
  nextflow run $binEvaluateFeatures --features features.npy --n $n --d $d --causal $c --i $i --model 'mRMR' -profile cluster
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
  echo 'model\tn\td\ti\tc\ttpr' >feature_selection.tsv
  cat feature_stats* >>feature_selection.tsv

  echo 'model\tn\td\ti\tc\t$stat' >prediction.tsv
  cat prediction_stats* >>prediction.tsv
  """

}
