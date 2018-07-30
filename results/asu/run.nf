#!/usr/bin/env nextflow

params.projectdir = '../../'
projectdir = file(params.projectdir)
params.out = "."

mat = file("$params.mat")
params.i = 100
params.B = '0,20,50'
params.causal = '10,30,50'

bins = file("$projectdir/scripts")
binRead = file("$bins/io/mat2npy.nf")
binSplit = file("$bins/io/train_test_split.nf")
binBenchmark = file("$bins/benchmark_real.nf")

process read_data {

  input:
    file binRead
    file binSplit
    file mat

  output:
    set val(mat.baseName),'x.npy','y.npy','featnames.npy' into datasets

  """
  nextflow run $binRead --mat $mat -profile cluster
  """

}

process split_data {

  input:
    file binSplit
    set val(mat), file('x.npy'), file('y.npy'), file('featnames.npy') from datasets
    each i from 1..params.i

  output:
    set val(mat),val(i),'x_train.npy','x_val.npy','y_train.npy','y_val.npy','featnames.npy' into splits

  """
  nextflow run $binSplit --x x.npy --y y.npy --split 0.2 -profile cluster
  """

}

process benchmark {

  input:
    file binBenchmark
    set val(mat), val(i), file('x_train.npy'), file('x_val.npy'), file('y_train.npy'), file('y_val.npy'), file('featnames.npy') from splits

  output:
    set val(mat), '*prediction.tsv' into features

  """
  d=`python -c 'import numpy as np; print(np.load("x_train.npy").shape[0])'`
  n=`python -c 'import numpy as np; print(np.load("x_train.npy").shape[1])'`
  nextflow run $binBenchmark --mode classification --projectdir $projectdir --n \$n --d \$d --B $params.B --causal $params.causal --i $i -profile bigmem
  mv prediction.tsv ${mat}_prediction.tsv
  """

}

features
  .groupTuple()
  .set { dataset_benchmarks }

process join_benchmarks {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    set val(mat), file('predictions*') from dataset_benchmarks

  output:
    file "${mat}_prediction.tsv"

  """
  head -n1 `ls | head -n1` >${mat}_prediction.tsv
  tail -n +2 predictions* | grep -v '==>' | grep -v -e '^\$' >>${mat}_prediction.tsv
  """

}
