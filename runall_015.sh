#!/bin/bash -l

echo =========================================================================
Rscript eval_megfeatures_glmnet.R conn_MEGPLANAR_LCMV 10 20 auc 1 0.15

echo =========================================================================
Rscript eval_megfeatures_glmnet.R conn_MEG_LCMV 10 20 auc 1 0.15

#echo =========================================================================
#sleep 120
#Rscript eval_megfeatures_glmnet.R conn_MEG_eLORETA 10 20 auc 1 0.15

#echo =========================================================================
#sleep 120
#Rscript eval_megfeatures_glmnet.R conn_MEGPLANAR_eLORETA 10 20 auc 1 0.15