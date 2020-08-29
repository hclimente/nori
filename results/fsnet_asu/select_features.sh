nextflow run ../../scripts/select_features.nf --input "${HOME}/data/asu/SMK_CAN_187.mat" \
--causal 20 --B 10 -profile cluster -resume "$@"
mv "${line[2]%.*}_hsic_lasso_C=20_SELECT=50_M=3_B=10.txt" "${line[1]}_hsic_lasso_C=20_SELECT=50_M=3_B=10.txt"
mv "${line[2]%.*}_mrmr_C=20.txt" "${line[1]}_mrmr_C=20.txt"
mv "${line[2]%.*}_lars_C=20.txt" "${line[1]}_lars_C=20.txt"
