../../scripts/select_features.nf --causal 2 --input test1.ped --map1 test1.map --ped2 test2.ped --map2 test2.map "$@"
rm test1_hsic_lasso_C=2_SELECT=50_M=3_B=5.txt test1_mrmr_C=2.txt test1_lars_C=2.txt
