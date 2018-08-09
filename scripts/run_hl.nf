#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

input_file = file(params.input)

// PARAMETERS
/////////////////////////////////////

// HSIC lasso
params.causal = 50
params.select = 50
params.M = 3
params.B = 0

C = params.causal
HL_SELECT = params.select
HL_M = params.M
HL_B = params.B
MODE = 'classification'

// READ DATA
/////////////////////////////////////
process read_genotype {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file PED from file("${params.input}.ped")
        file MAP from file("${params.input}.map")

    output:
        set 'x.npy', 'y.npy', 'featnames.npy' into data

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
        set file(X_TRAIN), file(Y_TRAIN), file(FEATNAMES) from data
    
    output:
        file 'features_hl.npy' into feature_idx

    script:
    template 'feature_selection/hsic_lasso.py'

}

process get_features {

    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
        file MAP from file("${params.input}.map")
        file feature_idx

    output:
        file "${params.input}_C=${C}_SELECT=${HL_SELECT}_M=${HL_M}_B=${HL_B}"

    """
#!/usr/bin/env python

import numpy as np

idx = np.load('$feature_idx')

with open('$MAP', 'r') as MAP, \
     open('${params.input}_C=${C}_SELECT=${HL_SELECT}_M=${HL_M}_B=${HL_B}', 'w') as FEATURES:
    for i, line in zip(range(np.max(idx) + 1), MAP.readlines()):
        if i in idx:
            line = line.strip().split(' ')
            snp = line[1]

            FEATURES.write(snp + '\\n')
    """

}
