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
params.B = '0,5,10'
B = params.B .split(",")

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
    else if (input_file.getExtension() == 'tsv') {
        METADATA = file('metadata.tsv')
        template 'io/pcbc2npy.py'
    }

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
        each SEED from 1..params.perms

    output:
        set val(SEED), "x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" into split_data

    script:
    template 'data_processing/train_test_split.py'

}

//  FEATURE SELECTION
/////////////////////////////////////
split_data.into { data_hsic; data_lasso; data_mrmr }

process run_lars {

    tag { "${C} (${I})" }
    clusterOptions = '-V -jc pcc-skl'

    input:
        each C from causal
        set I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_lasso
    
    output:
        set val('LARS'), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_lars.npy' into features_lars

    script:
    template 'feature_selection/lars.py'

}

process run_hsic_lasso {

    tag { "${C}, B = ${HL_B} (${I})" }
    clusterOptions = '-V -jc pcc-large'

    input:
	each C from causal
        set I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_hsic
        each HL_B from B
        each HL_M from M
        each HL_SELECT from params.hl_select
    
    output:
        set val("HSIC_lasso-B=$HL_B-M=$HL_M"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_hl.npy' into features_hsic

    script:
    template 'feature_selection/hsic_lasso.py'

}

process run_mrmr {

    tag { "${C} (${I})" }
    clusterOptions = '-V -jc pcc-large'

    input:
        each C from causal
        set I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_mrmr
    
    output:
        set val("mRMR"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_mrmr.npy' into features_mrmr

    script:
    template 'feature_selection/mrmr.py'

}

features = features_hsic .mix( features_lars, features_mrmr ) 
features .into { features_prediction; features_stability }

//  PREDICTION
/////////////////////////////////////

process prediction {

    tag { "${MODEL}, ${C} causal (${I})" }
    clusterOptions = '-V -jc pcc-skl'

    validExitStatus 0,77

    input:
        set MODEL,C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(SELECTED_FEATURES) from features_prediction

    output:
        set MODEL,C,I, file(Y_TEST),'y_pred.npy' into predictions

    script:
    if (MODE == 'regression') template 'classifier/kernel_svm.py'
    else if (MODE == 'classification') template 'classifier/knn.py'

}

process analyze_predictions {

    tag { "${MODEL}, ${C} causal (${I})" }
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
    cat prediction_stats* | cut -f1,4- | sort >>${input_file.baseName}_prediction.tsv
    """

}

//  FEATURE STABILITY ANALYSIS
/////////////////////////////////////
features_stability
    .groupTuple( by: [0,1] )
    .set { grouped_features }

process analyze_stability {

    tag { "${MODEL}, ${C} causal (${I})" }
    clusterOptions = '-V -jc pcc-skl'

    input:
        set MODEL,C,I, 'x_train*', 'y_train*', 'x_test*', 'y_test*', 'features_*' from grouped_features

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
        file "${input_file.baseName}_stability.tsv"

    """
    echo 'model\tsamples\tfeatures\tcausal\treplicates\tcomparison\tjaccard' >${input_file.baseName}_stability.tsv
    cat stability_stats* | sort >>${input_file.baseName}_stability.tsv
    """

}
