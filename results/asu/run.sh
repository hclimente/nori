for f in `ls /home/hclimente/data/asu/*.mat`
	do nextflow run ../../scripts/benchmark_real.nf --input $f --causal 10,20,30,40,50 --perms 100 -profile cluster -resume "$@"
done
