#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.perms = 10
params.n = [100, 1000, 10000]
params.d = [1000, 2500, 5000, 10000]
params.B = [0, 20, 50]
params.select = [10, 50, 100]
params.simulation = 'additive'

bins = file("${params.projectdir}/pipelines/scripts")

if (params.simulation == 'random') {
  binSimulateData = file("$bins/io/generate_non-linear_data.nf")
  causal = params.select
} else if (params.simulation == 'non-additive') {
  binSimulateData = file("$bins/io/yamada_non_additive.nf")
  causal = 3
} else if (params.simulation == 'additive') {
  binSimulateData = file("$bins/io/yamada_additive.nf")
  causal = 4
}

binHSICLasso = file("$bins/feature_selection/hsic_lasso.nf")
binLinear = file("$bins/classifiers/linear_classifier.nf")
binmRMR = file("$bins/feature_selection/mrmr.nf")
binClassifier = file("$bins/classifiers/kernel_svm.nf")
binFilter = file("$bins/feature_selection/filter_n.nf")
binEvaluatePredictions = file("$bins/analysis/evaluate_predictions.nf")
binEvaluateFeatures = file("$bins/analysis/evaluate_features.nf")

params.mode = 'regression'
svm = (params.mode == 'regression')? 'SVR' : 'SVC'
stat = (params.mode == 'regression')? 'mse' : 'accuracy'
linmod = (params.mode == 'regression')? 'LassoCV' : 'LogisticRegressionCV'

process simulate_data {

  input:
    each i from 1..params.perms
    each n from params.n
    each d from params.d
    each c from causal
    file binSimulateData

  output:
    set n,d,i,c,"x_train.npy","y_train.npy","x_val.npy","y_val.npy","featnames.npy" into data

  """
  nextflow run $binSimulateData --n $n --d $d --causal $c -profile cluster
  """

}

data.into { data_hsic; data_lasso; data_mrmr }

process run_HSIC_lasso {

  input:
    file binHSICLasso
    file binEvaluateFeatures
    each B from params.B
    set n,d,i,c,"x_train.npy","y_train.npy","x_val.npy","y_val.npy","featnames.npy" from data_hsic

  output:
    set n,d,i,c,B,'features.npy','x_train.npy','y_train.npy','x_val.npy','y_val.npy' into features_pred
    file 'feature_stats' into features_hsic

  """
  nextflow run $binHSICLasso --x x_train.npy --y y_train.npy --featnames featnames.npy --B $B --mode $params.mode --causal 50 -profile bigmem
  nextflow run $binEvaluateFeatures --features features.npy --n $n --d $d --causal $c --i $i --model 'hsic_lasso-b$B' -profile cluster
  """

}

process subset_HSIC_lasso_features {

  input:
    set n,d,i,c,B,"features.npy","x_train.npy","y_train.npy","x_val.npy","y_val.npy" from features_pred
    file binFilter
    file binClassifier
    file binEvaluatePredictions
    each c from causal

  output:
    file 'prediction_stats' into predictions_hsic

  """
  nextflow run $binFilter --selected_features features.npy --n $c -profile cluster
  nextflow run $binClassifier --x_train x_train.npy --y_train y_train.npy --x_val x_val.npy --selected_features filtered_features.npy --model $svm -profile cluster
  nextflow run $binEvaluatePredictions --y_val y_val.npy --predictions predictions.npy --features filtered_features.npy --stat $stat --n $n --d $d --causal $c --i $i --model 'hsic_lasso-b$B' -profile cluster
  """

}

process run_linear_model {

  input:
    file binLinear
    file binEvaluatePredictions
    file binEvaluateFeatures
    set n,d,i,c,"x_train.npy","y_train.npy","x_val.npy","y_val.npy","featnames.npy" from data_lasso

  output:
    file 'feature_stats' into features_lasso
    file 'prediction_stats' into predictions_lasso

  """
  nextflow run $binLinear --x_train x_train.npy --y_train y_train.npy --x_val x_val.npy --linmod $linmod --featnames featnames.npy -profile bigmem
  nextflow run $binEvaluatePredictions --y_val y_val.npy --stat $stat --predictions predictions.npy --features features.npy --n $n --d $d --causal $c --i $i --model 'lasso' -profile cluster
  nextflow run $binEvaluateFeatures --features features.npy --n $n --d $d --causal $c --i $i --model $linmod -profile cluster
  """

}

process run_mRMR {

  input:
    file binmRMR
    file binClassifier
    file binEvaluatePredictions
    file binEvaluateFeatures
    set n,d,i,c,"x_train.npy","y_train.npy","x_val.npy","y_val.npy","featnames.npy" from data_mrmr

  output:
    file 'feature_stats' into features_mrmr
    file 'prediction_stats' into predictions_mrmr

  """
  nextflow run $binmRMR --x x_train.npy --y y_train.npy --featnames featnames.npy --causal $c --mode $params.mode -profile bigmem
  nextflow run $binClassifier --x_train x_train.npy --y_train y_train.npy --x_val x_val.npy --selected_features features.npy --model SVR -profile cluster
  nextflow run $binEvaluatePredictions --y_val y_val.npy --stat $stat --predictions predictions.npy --features features.npy --n $n --d $d --causal $c --i $i --model 'mRMR' -profile cluster
  nextflow run $binEvaluateFeatures --features features.npy --n $n --d $d --causal $c --i $i --model 'mRMR' -profile cluster
  """

}

features = features_hsic. mix( features_lasso, features_mrmr )
predictions = predictions_hsic. mix( predictions_lasso, predictions_mrmr )

process process_output {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file "feature_stats*" from features. collect()
    file "prediction_stats*" from predictions. collect()

  output:
    file 'feature_selection.tsv'
    file 'prediction.tsv'

  """
  echo 'model\tsamples\tfeatures\tcausal\tselected\ti\ttpr' >feature_selection.tsv
  cat feature_stats* | sed 's/^hsic_lasso-b0/hsic_lasso/' >>feature_selection.tsv

  echo 'model\tsamples\tfeatures\tcausal\tselected\ti\t$stat' >prediction.tsv
  cat prediction_stats* | sed 's/^hsic_lasso-b0/hsic_lasso/' >>prediction.tsv
  """

}
