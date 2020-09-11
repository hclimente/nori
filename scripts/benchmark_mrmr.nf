#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

input_file = file(params.input)
N = 'None'
D = 'None'

// PARAMETERS
/////////////////////////////////////

// setup
SPLIT = 0.5
params.perms = 20
params.causal = '10,50'
causal = params.causal .toString().split(",")

// classifier
params.mode = 'classification'
MODE = params.mode
stat = (MODE == 'regression')? 'mse' : 'accuracy'

//  GENERATE DATA
/////////////////////////////////////
if (input_file.getExtension() == 'mat') {

    process read_matlab {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file INPUT_FILE from input_file

        output:
            file 'x.npy' into X
            file 'y.npy' into Y
            file 'featnames.npy' into FEATNAMES

        script:
        template 'io/mat2npy.py'

    }

    process normalize {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file X

        output:
            file "x_normalized.npy" into normalized_X

        script:
        template 'data_processing/normalize.py'

    }

}

process split_data {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file X
        file Y
        file FEATNAMES
        each SEED from 1..params.perms

    output:
        set val(SEED), "x_train.npy","y_train.npy","x_test.npy","y_test.npy","featnames.npy" into split_data

    script:
    template 'data_processing/screening_train_test_split.py'

}

//  FEATURE SELECTION
/////////////////////////////////////
process run_mrmr {

    clusterOptions = '-V -jc pcc-large'
    tag { "${C} (${I})" }

    input:
        each C from causal
        set I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from split_data
    
    output:
        set val("mRMR"), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_mrmr.npy' into features

    script:
    template 'feature_selection/mrmr.py'

}


//  PREDICTION
/////////////////////////////////////

process prediction {

    tag { "${MODEL}, ${C} causal (${I})" }
    clusterOptions = '-V -jc pcc-skl'

    validExitStatus 0,77

    input:
        set MODEL,C,I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(SELECTED_FEATURES) from features

    output:
        set MODEL,C,I, file(Y_TEST),'y_pred.npy' into predictions

    script:
    template 'classifier/kernel_svm.py'

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
