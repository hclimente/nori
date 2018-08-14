#!/usr/bin/env Rscript
'
Input variables:
    - PED: input .ped file.
    - MAP: input .map file.
    - Y:   (Optional.) Output variable.
Output files:
    - x.npy
    - y.npy
    - featnames.npy
'

library(snpStats)
library(RcppCNPy)

gwas <- read.pedfile("${PED}", snps = "${MAP}")

X <- as(gwas\$genotypes, "numeric")

if ('${Y}' == 'original') {
    Y <- gwas\$fam\$affected
} else {
    Y <- rep(${Y}, nrow(gwas\$fam))
}

npySave('x.npy', X)
npySave('y.npy', Y)
npySave('featnames.npy', seq(nrow(gwas\$map)) - 1 )