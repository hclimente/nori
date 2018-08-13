#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

// PARAMETERS
/////////////////////////////////////
// setup
params.perms = 5
params.replicates = 5
params.n = [100, 1000, 10000]
params.d = [1000, 2500, 5000, 10000]

params.data_generation = 'yamada_additive'
if (params.data_generation == 'random') causal = [5, 10, 20]
else if (params.data_generation == 'yamada_additive') causal = 4
else if (params.data_generation == 'yamada_nonadditive') causal = 3

// classifier
params.mode = 'regression'
MODE = params.mode
STAT = (MODE == 'regression')? 'mse' : 'accuracy'

// HSIC lasso
params.B = [0, 5, 10, 50]
params.M = 3
params.hl_select = 50

// localized HSIC lasso
params.lhl_path = ''

//  GENERATE DATA
/////////////////////////////////////
process simulate_data {

    clusterOptions = '-V -jc pcc-skl'

    input:
        each N from params.n
        each D from params.d
        each I from 1..params.perms
        each C from causal

    output:
        set N,D,I,C,"x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" into data

    script:
    if (params.data_generation == 'random') template 'data_processing/generate_data.py'
    else if (params.data_generation == 'yamada_additive') template 'data_processing/yamada_additive.py'
    else if (params.data_generation == 'yamada_nonadditive') template 'data_processing/yamada_nonadditive.py'

}

//  FEATURE SELECTION
/////////////////////////////////////
data.into { data_hsic; data_lhsic; data_lasso; data_mrmr }

process run_lars {

    clusterOptions = '-V -jc pcc-skl'

    input:
        each R from 1..params.replicates
        set N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_lasso
    
    output:
        set val('LARS'),N,D,I,C,R, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_lars.npy' into features_lars

    script:
    template 'feature_selection/lars.py'

}

process run_hsic_lasso {

    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    errorStrategy 'ignore'

    input:
        set N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_hsic
        each HL_M from params.M
        each HL_B from params.B
        each HL_SELECT from params.hl_select
        each R from 1..params.replicates
    
    output:
        set val("HSIC_lasso-B=$HL_B-M=$HL_M"),N,D,I,C,R, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_hl.npy' into features_hsic

    script:
    template 'feature_selection/hsic_lasso.py'

}

if (params.lhl_path != '') {

    lhl_main_pkg = file("$params.lhl_path/pyHSICLasso/")

    process run_localized_hsic_lasso {

        clusterOptions = '-V -jc pcc-large'
        validExitStatus 0,77
        errorStrategy 'ignore'

        input:
            set N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_lhsic
            file lhl_main_pkg
            each HL_SELECT from params.hl_select
            each R from 1..params.replicates
        
        output:
            set val('localized_HSIC_lasso'),N,D,I,C,R, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_lhl.npy' into features_lhsic

        script:
        template 'feature_selection/localized_hsic_lasso.py'

    }
} else {
    features_lhsic = Channel. empty()
}

process run_mrmr {

    clusterOptions = '-V -jc pcc-large'

    input:
        set N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_mrmr
        each R from 1..params.replicates
    
    output:
        set val("mRMR"),N,D,I,C,R, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_mrmr.npy' into features_mrmr

    script:
    template 'feature_selection/mrmr.py'

}

//  FEATURE STABILITY ANALYSIS
/////////////////////////////////////
features_hsic
    .mix( features_lhsic, features_lars, features_mrmr ) 
    .groupTuple( by: [0,1,2,3,4] )
    .into { features }


process analyze_stability {

    clusterOptions = '-V -jc pcc-skl'

    input:
        set MODEL,N,D,I,C,R, 'x_train*', 'y_train*', 'x_test*', 'y_test*', 'features_*' from features

    output:
        file 'stability_stats' into stability_stats

    script:
    template 'analysis/selection_stability.py'

}

process join_stability_stats {

    clusterOptions = '-V -jc pcc-skl'
    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
        file "stability_stats*" from stability_stats. collect()

    output:
        file "${params.data_generation}_stability.tsv"

    """
    echo 'model\tsamples\tfeatures\tcausal\ti\treplicates\tjaccard' >${params.data_generation}_stability.tsv
    cat stability_stats* | sort >>${params.data_generation}_stability.tsv
    """

}