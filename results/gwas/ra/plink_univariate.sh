merge_cc --file1 controls.bed --file2 ra.bed -with-docker hclimente/gwas-tools
plink --bfile merged --chr 1-22 --maf 0.05 --mind 0.1 --geno 0.1 --hwe 0.001 --make-bed -out merged
plink --bfile merged --model fisher
sed 's/^ \+//' plink.model | sed 's/ \+/\t/g' | sed 's/\t$//' >univariate_models.tsv
