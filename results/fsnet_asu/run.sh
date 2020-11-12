for f in `ls /home/hclimente/data/asu/*.mat`
	do nextflow run ../../scripts/benchmark_real.nf --input $f --causal 10,50,100 --perms 20 -resume "$@" -profile bigmem
done
