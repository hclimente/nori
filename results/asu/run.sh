for f in `ls /home/hclimente/data/asu/*.mat`
	do ./run.nf "$@" --mat $f -resume
done
