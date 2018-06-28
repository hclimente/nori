#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.perms = 10
params.n = [100, 1000, 10000]
params.d = [1000, 2500, 5000, 10000]
params.B = [0, 10, 20, 50]
params.causal = [10, 50, 100]

bins = file("${params.projectdir}/pipelines/scripts")
binSimulateData = file("$bins/io/generate_non-linear_data.nf")
binHSICLasso = file("$bins/methods/hsic_lasso.nf")
binLasso = file("$bins/methods/lasso.nf")
binmRMR = file("$bins/methods/mrmr.nf")
binKernelSVM = file("$bins/methods/kernel_svm.nf")
binSimulateData = file("$bins/io/generate_non-linear_data.nf")
binEvaluateSolution = file("$bins/analysis/evaluate_solution.nf")

process simulate_data {

  input:
    each i from 1..params.perms
    each n from params.n
    each d from params.d
    each c from params.causal
    file binSimulateData

  output:
    set n,d,i,c,"X_train.npy","Y_train.npy","X_test.npy","Y_test.npy","featnames.npy" into data

  """
  nextflow run $binSimulateData --n $n --d $d --causal $c -profile cluster
  """

}

data.into { data_hsic; data_lasso; data_mrmr }

process run_HSIC_lasso {

  errorStrategy 'ignore'

  input:
    file binHSICLasso
    file binEvaluateSolution
    each B from params.B
    set n,d,i,c,"X_train.npy","Y_train.npy","X_test.npy","Y_test.npy","featnames.npy" from data_hsic

  output:
    file 'feature_stats' into features_hsic
    file 'prediction_stats' into predictions_hsic

  """
  nextflow run $binHSICLasso --X X_train.npy --Y Y_train.npy --featnames featnames.npy --B $B --mode regression --causal $c -profile bigmem
  nextflow run $binKernelSVM --X X_train.npy --Y Y_train.npy --X_test X_test.npy --selected_features features --model SVR -profile cluster
  nextflow run $binEvaluateSolution --features features --Y Y_test.npy --predictions predictions --n $n --d $d --causal $c --i $i --model 'hsic_lasso-b$B' -profile cluster
  """

}

process run_lasso {

  input:
    file binLasso
    file binEvaluateSolution
    set n,d,i,c,"X_train.npy","Y_train.npy","X_test.npy","Y_test.npy","featnames.npy" from data_lasso

  output:
    file 'feature_stats' into features_lasso
    file 'prediction_stats' into predictions_lasso

  """
  nextflow run $binLasso --X X_train.npy --Y Y_train.npy --X_test X_test.npy --featnames featnames.npy -profile bigmem
  nextflow run $binEvaluateSolution --features features --Y Y_test.npy --predictions predictions --n $n --d $d --causal $c --i $i --model 'lasso' -profile cluster
  """

}

process run_mRMR {

  input:
    file binmRMR
    file binEvaluateSolution
    set n,d,i,c,"X_train.npy","Y_train.npy","X_test.npy","Y_test.npy","featnames.npy" from data_mrmr

  output:
    file 'feature_stats' into features_mrmr
    file 'prediction_stats' into predictions_mrmr

  """
  nextflow run $binmRMR --X X_train.npy --Y Y_train.npy --featnames featnames.npy --causal $c -profile bigmem
  nextflow run $binKernelSVM --X X_train.npy --Y Y_train.npy --X_test X_test.npy --selected_features features --model SVR -profile cluster
  nextflow run $binEvaluateSolution --features features --Y Y_test.npy --predictions predictions --n $n --d $d --causal $c --i $i --model 'mRMR' -profile cluster
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
  echo 'model\tn\td\ti\tc\tTPR' >feature_selection.tsv
  cat feature_stats* >>feature_selection.tsv

  echo 'model\tn\td\ti\tc\tr2' >prediction.tsv
  cat prediction_stats* >>prediction.tsv
  """

}
