#!/usr/bin/env nextflow

params.projectdir = '../../'
projectdir = file(params.projectdir)
params.out = "."

mats = file("$params.mats/*mat")

bins = file("$projectdir/pipelines")
binRead = file("$bins/scripts/io/mat2npy.nf")
binSplit = file("$bins/scripts/io/train_test_split.nf")
binBenchmark = file("$bins/benchmark_real.nf")

process read_data {

  input:
    file binRead
    file binSplit
    file mat from mats

  output:
    set val(mat.baseName), "X_train.npy", "X_test.npy", "Y_train.npy", "Y_test.npy", "featnames.npy" into data

  """
  nextflow run $binRead --mat $mat -profile cluster
  nextflow run $binSplit --X X.npy --Y Y.npy --split 0.2 -profile cluster
  """

}


process benchmark {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file binBenchmark
    set val(mat.baseName), x_train, x_test, y_train, y_test, featnames from data

  output:
    file 'features' into features

  """
  nextflow run $binBenchmark --mode classification -profile cluster --projectdir $projectdir
  """

}
