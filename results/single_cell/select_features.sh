while IFS=$'\t' read -r -a line;
do
    path="${HOME}/data/single_cell/${line[1]}/"
    nextflow run ../../scripts/select_features.nf --input "${path}${line[2]}" \
--metadata "${path}${line[3]}" --col_feats "${line[4]}" --col_id "${line[5]}" \
--col_y "${line[6]}" --causal 50 --B 10 -profile cluster -resume "$@"
done < datasets.tsv
