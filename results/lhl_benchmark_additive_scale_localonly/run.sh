../../scripts/benchmark_lhsic_only.nf "$@" --lhl_path ${HOME}/projects/lHSICLasso --B 0 --data_generation 'yamada_additive' --decomp "Eigen" --localonly "True" -with-trace -resume -profile cluster
