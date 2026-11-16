#!/bin/sh
conda create --prefix /home/alahmad/R432env -c conda-forge r-base=4.3.2
conda config --add envs_dirs /home/alahmad/
source activate R432env
conda install -c conda-forge r-readxl
conda install -c conda-forge r-dplyr
conda install -c conda-forge r-glmnet
conda install -c conda-forge r-caret
conda install -c conda-forge r-ROCR
conda install -c conda-forge r-pROC
conda deactivate
