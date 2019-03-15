#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

// PARAMETERS
/////////////////////////////////////
// setup
params.perms = 10
params.n = [100, 1000]
params.d = [1000, 2500, 5000]

params.data_generation = 'continuous'
causal = [5, 10, 20]

// classifier
params.mode = 'regression'

// HSIC lasso
params.B = [0,5,10,20]
params.M = 3
params.hl_select = 50

M = params.M
MODE = 'regression'
empty_array = file(params.empty_array)

//  GENERATE DATA
/////////////////////////////////////
process simulate_data {

    clusterOptions = '-V -jc pcc-large'

    input:
        each N from params.n
        each D from params.d
        each I from 1..params.perms
        each C from causal

    output:
        set N,D,I,C,"x_train.npy","y_train.npy",'covars_train.npy',"x_test.npy","y_test.npy","featnames.npy" into data

    script:
    template 'data_processing/generate_continuous_data.py'

}

//  FEATURE SELECTION
/////////////////////////////////////
data.into { data_no_covars; data_covars }

process run_hsic_lasso {

    tag { "${C}, B = ${HL_B}, M = ${HL_M} (${I})" }
    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    errorStrategy 'ignore'

    input:
        set N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(COVARS), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_covars
        each HL_M from M
        each HL_B from params.B
        each HL_SELECT from params.hl_select
    
    output:
        set val("HSIC_lasso_covars-B=$HL_B-M=$HL_M"),N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(COVARS), file(X_TEST), file(Y_TEST), 'features_hl.npy' into features_covars

    script:
    template 'feature_selection/hsic_lasso.py'

}

process run_hsic_lasso_no_covars {

    tag { "${C}, B = ${HL_B}, M = ${HL_M} (${I})" }
    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    errorStrategy 'ignore'

    input:
        set N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(UNUSED), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_no_covars
        file COVARS from empty_array
        each HL_M from M
        each HL_B from params.B
        each HL_SELECT from params.hl_select
    
    output:
        set val("HSIC_lasso_no_covars-B=$HL_B-M=$HL_M"),N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(COVARS), file(X_TEST), file(Y_TEST), 'features_hl.npy' into features_no_covars

    script:
    template 'feature_selection/hsic_lasso.py'

}

//  FEATURE SELECTION ANALYSIS
/////////////////////////////////////
features_covars
    .mix( features_no_covars ) 
    .into { features_qc }

process analyze_features {

    tag { "${MODEL}, ${C} causal (${I})" }
    clusterOptions = '-V -jc pcc-skl'

    input:
        set MODEL,N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(COVARS), file(X_TEST), file(Y_TEST), file(SELECTED_FEATURES) from features_qc

    output:
        file 'feature_stats' into feature_analyses

    script:
    template 'analysis/analyze_features.py'

}

process join_feature_analyses {

    clusterOptions = '-V -jc pcc-skl'
    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
        file "feature_stats*" from feature_analyses. collect()

    output:
        file "${params.data_generation}_feature_selection.tsv"

    """
    echo 'model\tsamples\tfeatures\tcausal\tselected\ti\ttpr' >${params.data_generation}_feature_selection.tsv
    cat feature_stats* | sort >>${params.data_generation}_feature_selection.tsv
    """

}