#!/bin/bash -l

###sleep 3600

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R coh_$1 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R coh_$1 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R coh_$1 10 20 auc 1 0.25

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corrv.R icoh_$1 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R icoh_$1 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R icoh_$1 10 20 auc 1 0.25

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R wpli_$1 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R wpli_$1 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet_alpha_corr.R wpli_$1 10 20 auc 1 0.25