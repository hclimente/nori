plink --bfile merged --r --ld-snp-list hla_snps.txt
sed 's/^ \+//' plink.ld | sed 's/ \+/\t/g' | sed 's/\t$//' >hla_biomarkers_ld.txt
