#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

// PARAMETERS
/////////////////////////////////////

// HSIC lasso
params.causal = 50
params.select = 50
params.M = 3
params.B = 5
params.type = 'classification'

M = String.valueOf(params.M) + ', discrete_x = True'

// READ DATA
/////////////////////////////////////
if (params.gt == null) {

    input_files = Channel
        .fromFilePairs( '*.{ped,map}' )
        .map { it -> it.flatten() }

    process set_phenotypes {

        clusterOptions = '-V -jc pcc-skl'

        input:
            set idx, file(PED), file(MAP) from input_files
            val Y from 1..10000

        output:
            set PED,'new_phenotype.map' into experiments

        script:
        """
        awk '{\$6 = "$Y"; print}' $MAP >new_phenotype.map
        """

    }

    process merge_datasets {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file 'input*' from experiments. collect()

        output:
            file 'merged.ped' into ped
            file 'merged.map' into map, map_out

        """
        plink --ped input2 --map input1 --merge input4 input3 --allow-extra-chr --recode --out merged
        """

    }

} else {

    ped = file("${params.gt}.ped")
    map = file("${params.gt}.map")
    map_out = file("${params.gt}.map")

}

process read_genotype {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file MAP from map
        file PED from ped

    output:
        set 'x.npy', 'y.npy','featnames.npy' into gwas

    script:
    template 'io/ped2npy.R' 

}

//  FEATURE SELECTION
/////////////////////////////////////
process run_hsic_lasso {

    clusterOptions = '-V -jc m1'

    input:
        set file(X_TRAIN), file(Y_TRAIN), file(FEATNAMES) from gwas
        val C from params.causal
        val HL_SELECT from params.select
        val HL_M from params.M
        val HL_B from params.B
        val MODE from params.type
    
    output:
        file 'features_hl.npy' into feature_idx

    script:
    template 'feature_selection/hsic_lasso.py'

}

process get_features {

    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
        file feature_idx
        file map_out
        val C from params.causal
        val HL_SELECT from params.select
        val HL_M from params.M
        val HL_B from params.B

    output:
        file "gwas_C=${C}_SELECT=${HL_SELECT}_M=${HL_M}_B=${HL_B}.txt"

    """
    #!/usr/bin/env python

    import numpy as np

    idx = np.load('$feature_idx')

    snps = []

    with open('$map_out', 'r') as MAP: 
        for line in MAP.readlines():
            snp = line.strip().split('\t')[1]
            snps.append(snp)

    with open('gwas_C=${C}_SELECT=${HL_SELECT}_M=${HL_M}_B=${HL_B}.txt', 'w') as FEATURES:
        for i in idx:
            FEATURES.write('{}\\n'.format(snps[i]))
    """

}
