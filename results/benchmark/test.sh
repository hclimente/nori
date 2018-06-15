../../pipelines/benchmark.nf --n 100 --d 1000 --B 20 --perms 2 -resume
mv feature_selection.tsv test_feature_selection.tsv
mv prediction.tsv test_prediction.tsv
