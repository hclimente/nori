for f in `ls /home/hclimente/data/asu/*.mat`
	do nextflow run ../../scripts/benchmark_real_lhsic_only.nf --input $f --lhl_path ${HOME}/projects/lHSICLasso "$@" -profile cluster -resume
done
