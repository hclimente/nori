../../pipelines/benchmark.nf --n 100 --d 1000 --B 20 --perms 2 --causal 5
mv feature_selection.tsv test_feature_selection.tsv
mv prediction.tsv test_prediction.tsv
git checkout feature_selection.tsv
git checkout prediction.tsv
