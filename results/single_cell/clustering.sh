while IFS=$'\t' read -r -a line;
do
    path="${HOME}/data/single_cell/${line[1]}/"
    nextflow run ../../scripts/clustering.nf --input "${path}${line[2]}" \
--metadata "${path}${line[3]}" --col_feats "${line[4]}" --col_id "${line[5]}" \
--col_y "${line[6]}" --causal 20 --B 10 -profile cluster -resume "$@"
    mv heatmap.png "${line[1]}_heatmap.png"
    mv dendrogram.png "${line[1]}_dendrogram.png"
done < datasets.tsv
