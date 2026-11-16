#!/bin/bash -l

### bash runall_spectral_corr.sh uncorrected

###sleep 3600

for cutoff in 0.20 0.15 0.10 0.05 0.00
do
  for channel in MEGPLANAR MEG
  do
    for method in Sensor MSP EBB COH eLORETA LCMV
    do
      echo =========================================================================
      echo $channel
      echo $method
      echo $cutoff
      Rscript eval_megfeatures_glmnet_alpha_corr.R $1_${channel}_${method} 10 20 auc 1 $cutoff
    done
  done
done
