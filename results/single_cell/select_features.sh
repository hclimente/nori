while IFS=$'\t' read -r -a line;
do
    path="${HOME}/data/single_cell/${line[1]}/"
    nextflow run ../../scripts/select_features.nf --input "${path}${line[2]}" \
--metadata "${path}${line[3]}" --col_feats "${line[4]}" --col_id "${line[5]}" \
--col_y "${line[6]}" --causal 50 --B 10 -profile cluster -resume "$@"
    mv "${line[2]%.*}_hsic_lasso_C=50_SELECT=50_M=3_B=10.txt" "${line[1]}_hsic_lasso_C=50_SELECT=50_M=3_B=10.txt"
    mv "${line[2]%.*}_mrmr_C=50.txt" "${line[1]}_mrmr_C=50.txt"
    mv "${line[2]%.*}_lars_C=50.txt" "${line[1]}_lars_C=50.txt"
done < datasets.tsv
