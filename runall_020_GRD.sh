#!/bin/bash -l

#sleep 3600

echo =========================================================================
Rscript eval_megfeatures_glmnet.R coh_MEGPLANAR_LCMV 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet.R icoh_MEGPLANAR_LCMV 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet.R wpli_MEGPLANAR_LCMV 10 20 auc 1 0.2

echo =========================================================================
Rscript eval_megfeatures_glmnet.R coh_MEGPLANAR_LCMV 10 20 auc 1 0.25

echo =========================================================================
Rscript eval_megfeatures_glmnet.R icoh_MEGPLANAR_LCMV 10 20 auc 1 0.25

echo =========================================================================
Rscript eval_megfeatures_glmnet.R wpli_MEGPLANAR_LCMV 10 20 auc 1 0.25

echo =========================================================================
Rscript eval_megfeatures_glmnet.R coh_MEGPLANAR_LCMV 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R icoh_MEGPLANAR_LCMV 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R wpli_MEGPLANAR_LCMV 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R coh_MEGPLANAR_eLORETA 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R icoh_MEGPLANAR_eLORETA 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R wpli_MEGPLANAR_eLORETA 10 20 auc 1 0.15
