#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

ped = file("${params.gt}.ped")
map = file("${params.gt}.map")
B = params.B

bins = file("${params.projectdir}/scripts")
binReadPed = file("$bins/io/ped2numeric.nf")
binHSICLasso = file("$bins/feature_selection/hsic_lasso.nf")

process read_data {

  input:
    file binReadPed
    file ped
    file map

  output:
    set "*.X.npy", "*.Y.npy", "*.featnames.npy" into data

  """
  nextflow run $binReadPed --gt $ped.baseName
  """

}


process run_HSIC_lasso {

  input:
    set "X.npy", "Y.npy", "featnames.npy" from data

  """
  nextflow run $binHSICLasso --x X.npy --y Y.npy --featnames featnames.npy --B $B --mode classification
  """

}
