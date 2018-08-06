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
params.B = '0'
B = params.B .split(",")

// localized HSIC lasso
params.lhl_path = '/Users/hclimente/projects/lHSICLasso/pyHSICLasso2/'
lhl_main_pkg = file("$params.lhl_path/lHSICLasso.py")
lhl_kernel_pkg = file("$params.lhl_path/kernel_tools.py")

//  GENERATE DATA
/////////////////////////////////////
process read_data {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file INPUT_FILE from input_file

    output:
        file 'x.npy' into X
        file 'y.npy' into Y
        file 'featnames.npy' into FEATNAMES

    script:

    if (input_file.getExtension() == 'mat') template 'io/mat2npy.py'
    else if (input_file.getExtension() == 'p53') template 'io/p53data2npy.py'

}

process split_data {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file X
        file Y
        file FEATNAMES
        each I from 1..params.perms
        each C from causal

    output:
        set val(C), val(I), "x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" into split_data

    script:
    template 'data_processing/train_test_split.py'

}

process normalize_data {

    clusterOptions = '-V -jc pcc-skl'

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from split_data

    output:
        set val(C), val(I), "x_train_normalized.npy","y_train.npy","x_test_normalized.npy","y_test.npy","featnames.npy" into normalized_splits

    script:
    template 'data_processing/normalize.py'

}

//  FEATURE SELECTION
/////////////////////////////////////
normalized_splits.into { data_hsic; data_lhsic; data_lasso; data_mrmr }

process run_lars {

    clusterOptions = '-V -jc pcc-skl'

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_lasso
    
    output:
        set val('LARS'), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'selected_features.npy' into features_lars

    script:
    template 'feature_selection/lars.py'

}

process run_hsic_lasso {

    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    errorStrategy 'ignore'

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_hsic
        each HL_B from B
        each HL_M from M
        each HL_SELECT from params.hl_select
    
    output:
        set val("HSIC_lasso-B=$HL_B-M=$HL_M"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'selected_features.npy' into features_hsic

    script:
    template 'feature_selection/hsic_lasso.py'

}

process run_localized_hsic_lasso {

    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    //errorStrategy 'ignore'

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_lhsic
        file lhl_main_pkg
        file lhl_kernel_pkg
        each HL_SELECT from params.hl_select
    
    output:
        set val('localized_HSIC_lasso'), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'selected_features.npy' into features_lhsic

    script:
    template 'feature_selection/localized_hsic_lasso.py'

}

process run_mrmr {

    clusterOptions = '-V -jc pcc-large'

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_mrmr
    
    output:
        set val("mRMR"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'selected_features.npy' into features_mrmr

    script:
    template 'feature_selection/mrmr.py'

}

//  PREDICTION
/////////////////////////////////////
features_prediction = features_hsic
    .mix( features_lhsic, features_lars, features_mrmr ) 

process prediction {

    clusterOptions = '-V -jc pcc-skl'

    validExitStatus 0,77

    input:
        set MODEL,C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(SELECTED_FEATURES) from features_prediction

    output:
        set MODEL,C,I, file(Y_TEST),'predictions.npy' into predictions

    script:
    if (MODE == 'regression') template 'classifier/kernel_svm.py'
    else if (MODE == 'classification') template 'classifier/knn.py'

}

//  PREDICTION ANALYSIS
/////////////////////////////////////
process analyze_predictions {

    clusterOptions = '-V -jc pcc-skl'

    input:
        set MODEL,C,I, file(Y_TEST),file(Y_PRED) from predictions

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
        file "${input_file.baseName}_prediction.tsv"

    """
    echo 'model\tselected\ti\t$stat' >${input_file.baseName}_prediction.tsv
    cat prediction_stats* | cut -f1,4- >>${input_file.baseName}_prediction.tsv
    """

}
