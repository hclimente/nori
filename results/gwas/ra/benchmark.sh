nextflow run ../../../scripts/benchmark_real.nf  --input ra.bed --bim1 ra.bim --fam1 ra.fam --bed2 controls.bed --bim2 controls.bim --fam2 controls.fam --B 20 --perms 5 -profile cluster -resume "$@"
