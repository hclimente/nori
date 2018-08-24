for f in `ls ${HOME}/projects/noridata/*.mat`
	do nextflow run ../../scripts/benchmark_real_lhsic_only.nf --input $f --lhl_path ${HOME}/projects/lHSICLasso --split 0.5 --decomp "Eigen" "$@" -profile cluster -resume
done
