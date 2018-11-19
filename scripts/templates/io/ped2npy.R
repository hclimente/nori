#!/usr/bin/env Rscript
'
Input variables:
    - PED: input .ped file.
    - MAP: input .map file.
Output files:
    - x.npy
    - y.npy
    - featnames.npy
'

library(snpStats)
library(RcppCNPy)

gwas <- read.pedfile("${PED}", snps = "${MAP}")

X <- as(gwas\$genotypes, "numeric")
X[is.na(X)] <- 0 # safeguard against missing genotypes
X <- X + rnorm(X, mean = 0, sd = .00001) # add Gaussian noise

Y <- gwas\$fam\$affected

npySave('x.npy', X)
npySave('y.npy', Y)
npySave('featnames.npy', seq(nrow(gwas\$map)) - 1 )
