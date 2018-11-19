#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

input_file = file(params.input)

// PARAMETERS
/////////////////////////////////////

// HSIC lasso
params.causal = 50
params.select = 50
params.M = 3
params.B = 5
params.type = 'classification'

// READ DATA
/////////////////////////////////////
if (input_file.getExtension() == 'tsv' || input_file.getExtension() == 'txt') {

    metadata = file(params.metadata)
    M = params.M
    
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
} else if (input_file.getExtension() == 'ped') {

    ped1 = input_file
    map1 = file(params.map1)
    ped2 = file(params.ped2)
    map2 = file(params.map2)

    input_files = Channel.from ( [ped1,map1], [ped2,map2] )

    // Uncomment
    //M = String.valueOf(params.M) + ', discrete_x = True'
    M = params.M

    process set_phenotypes {

        clusterOptions = '-V -jc pcc-skl'

        input:
            set file(PED), file(MAP) from input_files
            val Y from 1..2

        output:
            file MAP into maps
            file 'new_phenotype.ped' into peds

        script:
        """
        awk '{\$6 = "$Y"; print}' $PED >new_phenotype.ped
        """

    }

    process merge_datasets {

        clusterOptions = '-V -jc pcc-skl'

        input:
            file 'map*' from maps. collect()
            file 'ped*' from peds. collect()

        output:
            file 'merged.ped' into ped
            file 'merged.map' into map, map_out

        """
        plink --ped ped1 --map map1 --merge ped2 map2 --allow-extra-chr --recode --out merged
        """

    }

    process read_genotype {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file MAP from map
        file PED from ped

    output:
        file 'x.npy' into X
        file 'y.npy' into Y
        file 'featnames.npy' into FEATNAMES

    script:
    template 'io/ped2npy.R' 

    }

}

//  FEATURE SELECTION
/////////////////////////////////////
process run_hsic_lasso {

    clusterOptions = '-V -jc pcc-large'

    input:
        file X_TRAIN from X
        file Y_TRAIN from Y
        file FEATNAMES
        val C from params.causal
        val HL_SELECT from params.select
        val HL_M from params.M
        val HL_B from params.B
        val MODE from params.type
    
    output:
        set val("hsic_lasso_C=${C}_SELECT=${HL_SELECT}_M=${HL_M}_B=${HL_B}"), 'features_hl.npy' into features_hl

    script:
    template 'feature_selection/hsic_lasso.py'

}

process run_mrmr {

    clusterOptions = '-V -jc pcc-large'
    errorStrategy 'ignore'

    input:
        file X_TRAIN from X
        file Y_TRAIN from Y
        file FEATNAMES
        val C from params.causal
        val MODE from params.type
    
    output:
        set val("mrmr_C=${C}"), 'features_mrmr.npy' into features_mrmr

    script:
    template 'feature_selection/mrmr.py'

}

process run_lars {

    clusterOptions = '-V -jc pcc-skl'

    input:
        file X_TRAIN from X
        file Y_TRAIN from Y
        file FEATNAMES
        val C from params.causal
        val MODE from params.type
    
    output:
        set val("lars_C=${C}"), 'features_lars.npy' into features_lars

    script:
    template 'feature_selection/lars.py'

}

features = features_hl .mix( features_mrmr, features_lars ) 

//  OUTPUT FEATURE NAMES
/////////////////////////////////////
if (input_file.getExtension() == 'ped') {

    process get_snps {

        publishDir "$params.out", overwrite: true, mode: "copy"
        clusterOptions = '-V -jc pcc-skl'

        input:
            set METHOD, file(FEATURES) from features
            file map_out

        output:
            file "${input_file.baseName}_${METHOD}.txt"

        """
        #!/usr/bin/env python

        import numpy as np

        idx = np.load('$FEATURES')

        snps = []

        with open('$map_out', 'r') as MAP: 
            for line in MAP.readlines():
                snp = line.strip().split('\t')[1]
                snps.append(snp)

        with open('${input_file.baseName}_${METHOD}.txt', 'w') as FEATURES:
            for i in idx:
                FEATURES.write('{}\\n'.format(snps[i]))
        """

    }

} else {

    process get_features {

        publishDir "$params.out", overwrite: true, mode: "copy"
        clusterOptions = '-V -jc pcc-skl'

        input:
            set METHOD, file(FEATURES) from features
            file FEATNAMES

        output:
            file "${input_file.baseName}_${METHOD}.txt"
        """
        #!/usr/bin/env python

        import numpy as np

        idx = np.load('$FEATURES')
        featnames = np.load('$FEATNAMES')

        with open('${input_file.baseName}_${METHOD}.txt', 'w') as FEATURES:
            for i in idx:
                FEATURES.write('{}\\n'.format(featnames[i]))
        """

    }
}
