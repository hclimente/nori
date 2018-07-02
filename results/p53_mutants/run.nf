#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.data = "K8.data"

p53 = file(params.data)
B = 20
c = 10

bins = file("${params.projectdir}/pipelines/scripts")
binRead = file("$bins/io/read_p53mutants.nf")
binHSICLasso = file("$bins/methods/hsic_lasso.nf")
binSplit = file("$bins/io/train_test_split.nf")
binKernelSVM = file("$bins/methods/kernel_svm.nf")
binEvaluateSolution = file("$bins/analysis/evaluate_solution.nf")

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
    file 'features' into features

  """
  nextflow run $binHSICLasso --x X.npy --y Y.npy --featnames featnames.npy --causal $c --B $B --mode classification -profile bigmem
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
  nextflow run $binKernelSVM --x x_train.npy --y y_train.npy --x_test x_test.npy --selected_features $features --model SVC -profile cluster
  nextflow run $binEvaluateSolution --y y_test.npy --predictions predictions --causal $c --model 'hsic_lasso-b$B' --d 5408 --outcome categorical -profile cluster
  """

}
