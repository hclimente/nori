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

    process normalize_data {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file X

        output:
            file "x_normalized.npy" into normalized_X

        script:
        template 'data_processing/normalize.py'

    }

} else if (input_file.getExtension() == 'tsv' || input_file.getExtension() == 'txt') {

    metadata = file(params.metadata)
    
    process read_tsv {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file INPUT_FILE from input_file
            file METADATA from metadata
            val COL_FEATS from params.col_feats
            val COL_ID from params.col_id
            val COL_Y from params.col_y

        output:
            file 'x.npy' into RAW_X
            file 'y.npy' into Y
            file 'featnames.npy' into FEATNAMES

        script:
        template 'io/tsv2npy.py'

    }

    process impute_expression {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file X from RAW_X

        output:
            file 'x_imputed.npy' into X

        script:
        template 'data_processing/impute_magic.py'

    }

    process normalize_expression {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file X

        output:
            file "x_normalized.npy" into normalized_X

        script:
        template 'data_processing/normalize.py'

    }

}  else if (input_file.getExtension() == 'bed') {

    bed1 = input_file
    bim1 = file(params.bim1)
    fam1 = file(params.fam1)
    bed2 = file(params.bed2)
    bim2 = file(params.bim2)
    fam2 = file(params.fam2)

    input_files = Channel.from ( [bed1,bim1,fam1], [bed2,bim2,fam2] )

    M = String.valueOf(params.M) + ', discrete_x = True'

    process set_phenotypes {

        clusterOptions = '-V -jc pcc-skl'

        input:
            set file(BED), file(BIM), file(FAM) from input_files
            val Y from 1..2

        output:
            file BED into beds
            file BIM into bims
            file 'new_phenotype.fam' into fams

        script:
        """
        awk '{\$6 = "$Y"; print}' $FAM >new_phenotype.fam
        """

    }

    process merge_datasets {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file 'bed*' from beds. collect()
            file 'bim*' from bims. collect()
            file 'fam*' from fams. collect()

        output:
            file 'merged.bed' into bed
            file 'merged.bim' into bim
            file 'merged.fam' into fam, fam_out

        """
        cut -f2 bim1 bim2 | sort | uniq -c | grep ' 2' | cut -d' ' -f8 >intersection
        plink --bed bed1 --bim bim1 --fam fam1 --bmerge bed2 bim2 fam2 --maf --extract intersection --make-bed --out merged
        """

    }

    process read_genotype {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file BED from bed
        file BIM from bim
        file FAM from fam

    output:
        file 'x.npy' into normalized_X
        file 'y.npy' into Y
        file 'featnames.npy' into FEATNAMES

    script:
    template 'io/bed2npy.R' 

    }

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
split_data.into { data_raw; data_hsic; data_lasso; data_mrmr }

process do_nothing {

    tag { "${I}" }
    clusterOptions = '-V -jc pcc-skl'

    input:
        set I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_raw
    
    output:
        set val('Raw'), val('None'), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'all_features.npy' into features_raw

    script:
    template 'feature_selection/all_features.py'

}

process run_lars {

    tag { "${C} (${I})" }
    clusterOptions = '-V -jc pcc-skl'

    input:
        each C from causal
        set I, file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), file(FEATNAMES) from data_lasso
    
    output:
        set val('LARS'), val(C), val(I), file(X_TRAIN), file(Y_TRAIN), file(X_TEST), file(Y_TEST), 'features_lars.npy' into features_lars

    script:
    template 'feature_selection/lars_spams.py'

}

process run_hsic_lasso {

    tag { "${C}, B = ${HL_B} (${I})" }
    clusterOptions = '-V -jc pcc-large'
    validExitStatus 0,77
    errorStrategy 'ignore'

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

features = features_hsic .mix( features_lars, features_mrmr, features_raw ) 

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
    if (MODE == 'regression') template 'classifier/kernel_svm.py'
    else if (MODE == 'classification') template 'classifier/random_forest.py'

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
