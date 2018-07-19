#!/usr/bin/env nextflow

params.projectdir = '../../'
params.out = "."

params.x_train = 'x_train.npy'
params.x_val = 'x_val.npy'
params.y_train = 'y_train.npy'
params.y_val = 'y_val.npy'
params.featnames = 'featnames.npy'

x_train = file(params.x_train)
x_val = file(params.x_val)
y_train = file(params.y_train)
y_val = file(params.y_val)
featnames = file(params.featnames)

params.mode = 'regression'
svm = (params.mode == 'regression')? 'SVR' : 'SVC'
stat = (params.mode == 'regression')? 'mse' : 'accuracy'
linmod = (params.mode == 'regression')? 'LassoCV' : 'LogisticRegressionCV'

params.B = '0,20,50'
params.causal = '10,30,50'
params.n = 'None'
params.d = 'None'
params.i = 'None'

B = params.B.split(",")
causal = params.causal.split(",")

bins = file("$params.projectdir/scripts")
binHSICLasso = file("$bins/feature_selection/hsic_lasso.nf")
binLinear = file("$bins/classifiers/linear_classifier.nf")
binmRMR = file("$bins/feature_selection/mrmr.nf")
binFilter = file("$bins/feature_selection/filter_n.nf")
binClassifier = file("$bins/classifiers/knn.nf")
binEvaluatePredictions = file("$bins/analysis/evaluate_predictions.nf")

process run_HSIC_lasso {

  input:
    file binHSICLasso
    file binClassifier
    file binEvaluatePredictions
    each B from B
    file x_train
    file x_val
    file y_train
    file y_val
    file featnames

  output:
    set val(B),'features.npy',file(x_train),file(y_train),file(x_val),file(y_val) into features_hsic

  """
  nextflow run $binHSICLasso --x $x_train --y $y_train --featnames $featnames --B $B --mode $params.mode --select ${Collections.max(params.select)} -profile bigmem
  """

}

process subset_HSIC_lasso_features {

  input:
    set B,features,x_train,y_train,x_val,y_val from features_hsic
    file binFilter
    file binClassifier
    file binEvaluatePredictions
    each c from causal
    file x_train
    file x_val
    file y_train
    file y_val
    file featnames

  output:
    file 'prediction_stats' into predictions_hsic

  """
  nextflow run $binFilter --selected_features $features --n $c -profile cluster
  nextflow run $binClassifier --x_train $x_train --y_train $y_train --x_val $x_val --selected_features filtered_features.npy --model $svm -profile cluster
  nextflow run $binEvaluatePredictions --y_val $y_val --predictions predictions.npy --features filtered_features.npy --stat $stat --n $params.n --d $params.d --causal $c --i $params.i --model 'hsic_lasso-b$B' -profile cluster
  """

}

process run_linear_model {

  input:
    file binLinear
    file binEvaluatePredictions
    file x_train
    file x_val
    file y_train
    file y_val
    file featnames

  output:
    file 'prediction_stats' into predictions_lasso

  """
  nextflow run $binLinear --x_train $x_train --y_train $y_train --x_val $x_val --linmod $linmod --featnames $featnames -profile bigmem
  nextflow run $binEvaluatePredictions --y_val $y_val --predictions predictions.npy --features features.npy --stat $stat --n $params.n --d $params.d --causal None --i $params.i --model $linmod -profile cluster
  """

}

process run_mRMR {

  input:
    file binmRMR
    file binClassifier
    file binEvaluatePredictions
    each c from causal
    file x_train
    file x_val
    file y_train
    file y_val

  output:
    file 'prediction_stats' into predictions_mrmr

  """
  nextflow run $binmRMR --x $x_train --y $y_train --featnames $featnames --select $c --mode $params.mode -profile bigmem
  nextflow run $binClassifier --x_train $x_train --y_train $y_train --x_val $x_val --selected_features features.npy --model $svm -profile cluster
  nextflow run $binEvaluatePredictions --y_val $y_val --predictions predictions.npy --features features.npy --stat $stat --n $params.n --d $params.d --causal $c --i $params.i --model 'mRMR' -profile cluster
  """

}

predictions = predictions_hsic. mix( predictions_lasso, predictions_mrmr )

process process_output {

  publishDir "$params.out", overwrite: true, mode: "copy"

  input:
    file "prediction_stats*" from predictions. collect()

  output:
    file 'prediction.tsv'

  """
  echo 'model\tsamples\tfeatures\tcausal\tselected\ti\t$stat' >prediction.tsv
  cat prediction_stats* | sed 's/^hsic_lasso-b0/hsic_lasso/' >>prediction.tsv
  """

}
