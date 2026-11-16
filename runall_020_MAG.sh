#!/bin/bash -l

echo =========================================================================
Rscript eval_megfeatures_glmnet.R coh_$1 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R coh_$1 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet.R coh_$1 10 20 auc 1 0.25

echo =========================================================================
Rscript eval_megfeatures_glmnet.R icoh_$1 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R icoh_$1 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet.R icoh_$1 10 20 auc 1 0.25

echo =========================================================================
Rscript eval_megfeatures_glmnet.R wpli_$1 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R wpli_$1 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet.R wpli_$1 10 20 auc 1 0.25