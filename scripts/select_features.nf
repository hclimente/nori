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
            file 'merged.bim' into bim, bim_out
            file 'merged.fam' into fam

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
        file 'x.npy' into X
        file 'y.npy' into Y
        file 'featnames.npy' into FEATNAMES

    script:
    template 'io/bed2npy.R' 

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
        val HL_M from M
        val HL_B from params.B
        val MODE from params.type
    
    output:
        set val("hsic_lasso_C=${C}_SELECT=${HL_SELECT}_M=${params.M}_B=${HL_B}"), 'features_hl.npy' into features_hl

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
    template 'feature_selection/lars_spams.py'

}

features = features_hl .mix( features_mrmr, features_lars ) 

//  OUTPUT FEATURE NAMES
/////////////////////////////////////
if (input_file.getExtension() == 'bed') {

    process get_snps {

        publishDir "$params.out", overwrite: true, mode: "copy"
        clusterOptions = '-V -jc pcc-skl'

        input:
            set METHOD, file(FEATURES) from features
            file bim_out

        output:
            file "${input_file.baseName}_${METHOD}.txt"

        """
        #!/usr/bin/env python

        import numpy as np

        idx = np.load('$FEATURES')

        snps = []

        with open('$bim_out', 'r') as BIM: 
            for line in BIM.readlines():
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
