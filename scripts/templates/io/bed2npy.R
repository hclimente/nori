#!/usr/bin/env Rscript
'
Input variables:
    - BED: input .bed file.
    - BIM: input .bim file.
    - FAM: input .fam file.
Output files:
    - x.npy
    - y.npy
    - featnames.npy
'

library(snpStats)
library(RcppCNPy)

gwas <- read.plink("${BED}", "${BIM}", "${FAM}")

X <- as(gwas\$genotypes, "numeric")
X[is.na(X)] <- 0 # safeguard against missing genotypes

Y <- gwas\$fam\$affected

npySave('x.npy', X)
npySave('y.npy', Y)
npySave('featnames.npy', seq(nrow(gwas\$map)) - 1 )
