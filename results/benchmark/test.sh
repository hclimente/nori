../../scripts/benchmark.nf --n 500 --d 1000 --B 0 --perms 3 --causal 5 "$@"
mv feature_selection.tsv test_feature_selection.tsv
mv prediction.tsv test_prediction.tsv
git checkout feature_selection.tsv
git checkout prediction.tsv
