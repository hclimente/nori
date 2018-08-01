#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

input_file = file(params.input)
N = 'None'
D = 'None'

// PARAMETERS
/////////////////////////////////////

// setup
SPLIT = 0.2
params.perms = 10
params.causal = '10,25,50'
causal = params .causal.split(",")

// classifier
params.mode = 'classification'
MODE = params.mode
stat = (MODE == 'regression')? 'mse' : 'accuracy'

// HSIC lasso
params.hl_select = 50
params.M = 3
M = params.M
params.B = '0,5,10,50'
B = params.B .split(",")

//  GENERATE DATA
/////////////////////////////////////
process read_data {

    input:
        file input_file

    output:
        file 'x.npy' into X
        file 'y.npy' into Y
        file 'featnames.npy' into FEATNAMES

    script:

    if (input_file.getExtension() == 'mat') template 'io/mat2npy.py'
    else if (input_file.getExtension() == 'p53') template 'io/p53data2npy.py'

}

process split_data {

    input:
        file X
        file Y
        file FEATNAMES
        each I from 1..params.perms
        each C from causal

    output:
        set val(C), val(I), "x_train.npy","y_train.npy","x_val.npy","y_val.npy","featnames.npy" into split_data

    script:
    template 'analysis/train_test_split.py'

}

//  FEATURE SELECTION
/////////////////////////////////////
split_data.into { data_hsic; data_lasso; data_mrmr }

process run_lars {

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_VAL), file(Y_VAL), file(FEATNAMES) from data_lasso
    
    output:
        set val('LARS'), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_VAL), file(Y_VAL), 'features.npy' into features_lars

    script:
    template 'feature_selection/lars.py'

}

process run_hsic_lasso {

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_VAL), file(Y_VAL), file(FEATNAMES) from data_hsic
        each HL_B from B
        each HL_M from M
        each HL_SELECT from params.hl_select
    
    output:
        set val("HSIC_lasso-B=$HL_B-M=$HL_M"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_VAL), file(Y_VAL), 'features.npy' into features_hsic

    script:
    template 'feature_selection/hsic_lasso.py'

}

process run_mrmr {

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_VAL), file(Y_VAL), file(FEATNAMES) from data_mrmr
    
    output:
        set val("mRMR"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_VAL), file(Y_VAL), 'features.npy' into features_mrmr

    script:
    template 'feature_selection/mrmr.py'

}

//  PREDICTION
/////////////////////////////////////
features_prediction = features_hsic
    .mix( features_lars, features_mrmr ) 

process prediction {

    input:
        set MODEL,C,I, file(X_TRAIN), file(Y_TRAIN), file(X_VAL), file(Y_VAL), file(SELECTED_FEATURES) from features_prediction

    output:
        set MODEL,C,I, file(Y_VAL),'predictions.npy' into predictions

    script:
    if (MODE == 'regression') template 'classifier/kernel_svm.py'
    else if (MODE == 'classification') template 'classifier/knn.py'

}

//  PREDICTION ANALYSIS
/////////////////////////////////////
process analyze_predictions {

    input:
        set MODEL,C,I, file(Y_VAL),file(Y_PRED) from predictions

    output:
        file 'prediction_stats' into prediction_analysis

    script:
    template 'analysis/analyze_predictions.py'

}

process join_prediction_analyses {

    publishDir "$params.out", overwrite: true, mode: "copy"

    input:
        file "prediction_stats*" from prediction_analysis. collect()

    output:
        file "${input_file.baseName}_prediction.tsv"

    """
    echo 'model\tsamples\tfeatures\tcausal\tselected\ti\t$stat' >${input_file.baseName}_prediction.tsv
    cat prediction_stats* | sed 's/^hsic_lasso-b0/hsic_lasso/' >>${input_file.baseName}_prediction.tsv
    """

}