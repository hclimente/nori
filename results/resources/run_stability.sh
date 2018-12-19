# manually add list of number of permutations to benchmark.nf
../../scripts/benchmark.nf "$@" --n 1000 --d 2500 --data_generation random -with-trace -resume -profile cluster
