#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.data = "K8.data"
stat = 'accuracy'

p53 = file(params.data)
B = 20
c = 10

bins = file("${params.projectdir}/pipelines/scripts")
binRead = file("$bins/io/read_p53mutants.nf")
binHSICLasso = file("$bins/feature_selection/hsic_lasso.nf")
binSplit = file("$bins/io/train_test_split.nf")
binKernelSVM = file("$bins/classifiers/kernel_svm.nf")
binEvaluatePredictions = file("$bins/analysis/evaluate_predictions.nf")

process read_data {

  input:
    file binRead
    file p53

  output:
    set "X.npy", "Y.npy", "featnames.npy" into data_fs, data_reg

  """
  nextflow run $binRead --data $p53
  """

}


process run_HSIC_lasso {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    set "X.npy", "Y.npy", "featnames.npy" from data_fs

  output:
    file 'features.npy' into features

  """
  nextflow run $binHSICLasso --x X.npy --y Y.npy --featnames featnames.npy --B $B --mode classification --causal $c -profile bigmem
  """

}

process regression {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    set "X.npy", "Y.npy", "featnames.npy" from data_reg
    file features

  output:
    file 'prediction_stats'

  """
  nextflow run $binSplit --x X.npy --y Y.npy -profile cluster
  nextflow run $binKernelSVM --x_train x_train.npy --y_train y_train.npy --x_val x_val.npy --selected_features $features --model SVC -profile cluster
  nextflow run $binEvaluatePredictions --y_val y_val.npy --predictions predictions.npy --stat stat --n None --d None --causal $c --i None --model hsic_lasso-b$B -profile cluster
  """

}
