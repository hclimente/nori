nextflow run ../../scripts/benchmark_real.nf --input normalized_expression.tsv --causal 10,20,30,40,50 --perms 100 -profile cluster -resume "$@"
