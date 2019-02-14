../../scripts/benchmark.nf "$@" --M '3, n_jobs=1' --n 1000 --d 2500 --data_generation random -with-trace -resume -profile cluster
mv trace.txt resources_trace.txt
