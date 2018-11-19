while IFS=$'\t' read -r -a line;
do
    path="${HOME}/data/single_cell/${line[1]}/"
    nextflow run ../../scripts/benchmark_real.nf --input "${path}${line[2]}" \
--metadata "${path}${line[3]}" --col_feats "${line[4]}" --col_id "${line[5]}" \
--col_y "${line[6]}" --causal 10,20,30,40,50,80,100 --perms 100 --B 5,10,20 -profile cluster -resume "$@"
    mv "${line[2]%.*}_prediction.tsv" "${line[1]}_prediction.tsv"
done < datasets.tsv
