#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

p53 = file("K8.data")
B = 50

bins = file("${params.projectdir}/pipelines/scripts")
binRead = file("$bins/io/read_p53mutants.nf")
binHSICLasso = file("$bins/methods/hsic_lasso.nf")

process read_data {

  input:
    file binRead
    file p53

  output:
    set "X.npy", "Y.npy", "featnames.npy" into data

  """
  nextflow run $binRead --data $p53
  """

}


process run_HSIC_lasso {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    set "X.npy", "Y.npy", "featnames.npy" from data

  output:
    file 'features'

  """
  nextflow run $binHSICLasso --X X.npy --Y Y.npy --featnames featnames.npy --causal 10 --B $B --mode classification -profile bigmem
  """

}
