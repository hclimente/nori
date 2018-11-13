../../scripts/benchmark_real.nf --input test.tsv --i 2 --causal 5,50 --B 0,10 --perms 3 --metadata metadata.tsv --col_feats tracking_id --col_id UID --col_y Cell_Type_of_Origin "$@"
rm test_prediction.tsv
../../scripts/select_features.nf --input test.tsv --causal 50 --B 10 --metadata metadata.tsv --col_feats tracking_id --col_id UID --col_y Cell_Type_of_Origin "$@"
rm test_hsic_lasso_C=50_SELECT=50_M=3_B=10.txt test_mrmr_C=50.txt test_lars_C=50.txt
