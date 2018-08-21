for f in `ls ${HOME}/projects/noridata/*.mat`
	do nextflow run ../../scripts/benchmark_real.nf --input $f "$@" -profile cluster -resume
done
