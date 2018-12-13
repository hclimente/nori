# manually add list of number of permutations to benchmark.nf
../../scripts/benchmark.nf "$@" --n 10000 --d 10000 --data_generation random -with-trace -resume -profile cluster
