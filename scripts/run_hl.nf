#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

input_files = Channel
    .fromFilePairs( '*.{ped,map}' )
    .map { it -> it.flatten() }

// PARAMETERS
/////////////////////////////////////

// HSIC lasso
params.causal = 50
params.select = 50
params.M = '3, discrete_x = True'
params.B = 5

C = params.causal
HL_SELECT = params.select
HL_M = params.M
HL_B = params.B
MODE = 'classification'

// READ DATA
/////////////////////////////////////
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
        file 'merged.ped' into merged_ped
        file 'merged.map' into merged_map

    """
    plink --ped input2 --map input1 --merge input4 input3 --allow-extra-chr --recode --out merged
    """

}

process read_genotype {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file MAP from merged_map
        file PED from merged_ped

    output:
        set 'x.npy', 'y.npy','featnames.npy' into gwas

    script:
    template 'io/ped2npy.R' 

}

//  FEATURE SELECTION
/////////////////////////////////////
process run_hsic_lasso {

    clusterOptions = '-V -jc m1'
    validExitStatus 0,77
    errorStrategy 'ignore'

    input:
        set file(X_TRAIN), file(Y_TRAIN), file(FEATNAMES) from gwas
    
    output:
        file 'features_hl.npy' into feature_idx

    script:
    template 'feature_selection/hsic_lasso.py'

}

process get_features {

    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
        file feature_idx

    output:
        file "out.txt"

    """
#!/usr/bin/env python

import numpy as np

idx = np.load('$feature_idx')
np.savetxt('out.txt', idx)
    """

}
