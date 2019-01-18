merge_cc --file1 controls.bed --file2 t2d.bed -with-docker hclimente/gwas-tools
plink --bfile merged --model fisher
sed 's/^ \+//' plink.model | sed 's/ \+/\t/g' | sed 's/\t$//' >univariate_models.tsv