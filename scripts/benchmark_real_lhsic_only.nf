#!/usr/bin/env nextflow

// python ssh h --B 0

params.projectdir = '../../'
params.out = "."

input_file = file(params.input)
N = 'None'
D = 'None'

// PARAMETERS
/////////////////////////////////////

// setup
SPLIT = 0.5
params.perms = 10
params.causal = '10,25,50'
causal = params .causal.split(",")

// classifier
params.mode = 'classification'
MODE = params.mode
stat = (MODE == 'regression')? 'mse' : 'accuracy'

// localized HSIC lasso
params.lhl_select = 50
params.num_clusters = [5]
params.lhl_path = ''
params.beta_scale = [2]

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

process normalize_data {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file X

    output:
        file "x_normalized.npy" into normalized_X

    script:
    template 'data_processing/normalize.py'

}

process split_data {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file X from normalized_X
        file Y
        file FEATNAMES
        each I from 1..params.perms
        each C from causal

    output:
        set val(C), val(I), "x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" into split_data

    script:
    template 'data_processing/train_test_split.py'

}

//  FEATURE SELECTION
/////////////////////////////////////
lhl_main_pkg = file("$params.lhl_path/pyHSICLasso/")

process run_localized_hsic_lasso {

    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    //errorStrategy 'ignore'

    input:
        set C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from split_data
        file lhl_main_pkg
        each HL_SELECT from params.lhl_select
        each LHL_NUM_CLUSTERS from params.num_clusters
        each BETA_SCALE from params.beta_scale

    output:
        set val("localized_HSIC_lasso-K=${LHL_NUM_CLUSTERS}-S=${BETA_SCALE}"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_lhl.npy' into features_lhsic

    script:
    template 'feature_selection/localized_hsic_lasso.py'

}


//  PREDICTION
/////////////////////////////////////


process prediction {

    clusterOptions = '-V -jc pcc-skl'

    validExitStatus 0,77

    input:
        set MODEL,C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(SELECTED_FEATURES) from features_lhsic

    output:
        set MODEL,C,I, file(Y_TEST),'y_pred.npy' into predictions

    script:
    if (MODE == 'regression') template 'classifier/kernel_svm.py'
    else if (MODE == 'classification') template 'classifier/xgboost.py'

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
