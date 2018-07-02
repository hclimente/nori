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
    set val(mat.baseName),'x_train.npy','x_test.npy','y_train.npy','y_test.npy','featnames.npy' into datasets

  """
  nextflow run $binRead --mat $mat -profile cluster
  nextflow run $binSplit --x X.npy --y Y.npy --split 0.2 -profile cluster
  """

}


process benchmark {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file binBenchmark
    set val(mat), file('x_train.npy'), file('x_test.npy'), file('y_train.npy'), file('y_test.npy'), file('featnames.npy') from datasets

  output:
    file 'prediction.tsv' into features

  """
  nextflow run $binBenchmark --mode classification --projectdir $projectdir
  mv prediction.tsv ${mat}_prediction.tsv
  """

}
