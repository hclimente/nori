nextflow run ../../scripts/benchmark_real.nf --input metagenome.mat --split 0.5 --causal 16 --perms 20 -resume "$@" -profile bigmem
