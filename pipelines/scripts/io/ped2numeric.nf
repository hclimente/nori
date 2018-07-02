#!/usr/bin/env nextflow

params.out = "."

ped = file("${params.gt}.ped")
map = file("${params.gt}.map")

process ped2numeric {

  input:
    file ped
    file map

  output:
    file "${ped.baseName}.numeric.tsv" into numeric

  """
	#!/usr/bin/env Rscript
  library(snpStats)

  gwas <- read.pedfile("$ped", snps = "$map")

  X <- as(gwas\$genotypes, "numeric")
  Y <- gwas\$fam\$affected

  X <- cbind(Y,X)

  write.table(X, file = '${ped.baseName}.numeric.tsv', sep = "\\t", quote = F, row.names = F)
  """

}

process numeric2npy {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file numeric

  output:
    file "*.npy"

  """
  #!/usr/bin/env python

  from pyHSICLasso import HSICLasso
  import numpy as np

  hl = HSICLasso()
  hl.input("$numeric")

  np.save("X.npy", hl.X_in)
  np.save("Y.npy", hl.Y_in)
  np.save("featnames.npy", hl.featname)
  """

}
