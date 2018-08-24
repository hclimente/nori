#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

// PARAMETERS
/////////////////////////////////////
// setup
DECOMPOAITION = params.decomp
LOCALONLY = params.localonly
NOISE = params.noise

params.perms = 10
params.n = [50] 
params.d = [1000,2500,5000, 10000]

params.data_generation = 'yamada_additive'
if (params.data_generation == 'random') causal = [5, 10, 20]
else if (params.data_generation == 'yamada_additive') causal = 4
else if (params.data_generation == 'yamada_nonadditive') causal = 3

// classifier
params.mode = 'regression'
MODE = params.mode
STAT = (MODE == 'regression')? 'mse' : 'accuracy'
params.lhl_select = 50

// localized HSIC lasso
params.num_clusters = [5]
params.lhl_path = ''
params.beta_scale = [1]

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

lhl_main_pkg = file("$params.lhl_path/pyHSICLasso/")

process run_localized_hsic_lasso {

    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    //errorStrategy 'ignore'

    input:
        set N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data
        file lhl_main_pkg
        each HL_SELECT from params.lhl_select
        each LHL_NUM_CLUSTERS from params.num_clusters
        each BETA_SCALE from params.beta_scale

    
    output:
        set val("localized_HSIC_lasso-K=${LHL_NUM_CLUSTERS}-S=${BETA_SCALE}"),N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_lhl.npy' into features_lhsic

    script:
    template 'feature_selection/localized_hsic_lasso.py'

}

//  FEATURE SELECTION ANALYSIS
/////////////////////////////////////
features_lhsic
    .into { features_qc; features_prediction }

process analyze_features {

    clusterOptions = '-V -jc pcc-skl'

    input:
        set MODEL,N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(SELECTED_FEATURES) from features_qc

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
    cat feature_stats* >>${params.data_generation}_feature_selection.tsv
    """

}

//  PREDICTION
/////////////////////////////////////
process prediction {

    clusterOptions = '-V -jc pcc-skl'
    validExitStatus 0,77

    input:
        set MODEL,N,D,I,C, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(SELECTED_FEATURES) from features_prediction

    output:
        set MODEL,N,D,I,C, file(Y_TEST),'y_pred.npy' into predictions

    script:
    if (MODE == 'regression') template 'classifier/kernel_svm.py'
    else if (MODE == 'classification') template 'classifier/knn.py'

}

//  PREDICTION ANALYSIS
/////////////////////////////////////
process analyze_predictions {

    clusterOptions = '-V -jc pcc-skl'
    
    input:
        set MODEL,N,D,I,C, file(Y_TEST),file(Y_PRED) from predictions

    output:
        file 'prediction_stats' into prediction_analysis

    script:
    template 'analysis/analyze_predictions.py'

}

process join_prediction_analyses {

    clusterOptions = '-V -jc pcc-skl'
    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
        file "prediction_stats*" from prediction_analysis. collect()

    output:
        file "${params.data_generation}_prediction_lhsic.tsv"

    """
    echo 'model\tsamples\tfeatures\tcausal\ti\t$STAT' >${params.data_generation}_prediction_lhsic.tsv
    cat prediction_stats* >>${params.data_generation}_prediction_lhsic.tsv
    """

}
