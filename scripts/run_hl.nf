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
process read_genotype {

    clusterOptions = '-V -jc pcc-skl'

    input:
        set idx, file(PED), file(MAP) from input_files
        val Y from 1..10000

    output:
        set 'x.npy', 'y.npy','featnames.npy' into experiment

    script:
    template 'io/ped2npy.R' 

}

process merge_datasets {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file 'input*' from experiment. collect()

    output:
        set 'x.npy', 'y.npy','featnames.npy' into gwas
        file 'featnames.npy' into snps

    """
#!/usr/bin/env python
import numpy as np
from glob import glob

X = []
Y = []

inputs = [ int(x[5:]) for x in glob('input*') ]

for i in range(min(inputs), max(inputs), 3):
    x = np.load('input' + str(i))
    x = x.astype('int8')
    X.append(x)

    y = np.load('input' + str(i + 1))
    y = y.astype('int8')
    Y.append(y)

    featnames = np.load('input' + str(i + 2))

X = np.concatenate(X, axis = 0)
Y = np.concatenate(Y, axis = 0)

np.save('x.npy', X)
np.save('y.npy', Y)
np.save('featnames.npy', featnames)
    """

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
