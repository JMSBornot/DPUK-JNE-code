#library(readxl)
library(R.matlab)

library(dplyr)
library(glmnet)
library(caret)
library(ROCR)
library(pROC)

source("nested_kfold_glmnet_alpha_corr.R")

args <- commandArgs(trailingOnly=TRUE)
Nargs <- length(args)
cat("Number of input arguments:", Nargs, "\n")

# Label for stats table
label <- args[1]
# K for K-fold cross-validation
K <- as.integer(args[2])
# Number of Monte Carlo replications
NMC <- as.integer(args[3])
# type of error measure
tmeas <- args[4]
# GLMNET's alpha
alpha <- as.numeric(args[5])
# predictors selected by correlation cutoff
corr_cutoff <- as.numeric(args[6])

fc <- TRUE
fn <- TRUE

cat("\nlabel:", label, "\n")

#features_gamma_conn_MEG_eLORETA.mat
dat <- readMat(paste0("P:/alahmad/Matlab/BioFIND-data-paper/", "features_gamma_", label, ".mat"))

# Concatenate the data for CN and MCI groups
isCN <- (dat$group.num == 1)
isMCI <- (dat$group.num == 2)
X <- rbind(as.matrix(dat$features[isCN,]), as.matrix(dat$features[isMCI,]))
rm(dat)

# Binomial group variable (CN=0 and MCI=1)
y <- c(rep(0, sum(isCN)), rep(1, sum(isMCI)))

# Covariates
cov <- c()

#filename <- paste0("glmnet", "_", label, "_K", K, "_NMC", NMC, "_alpha", alpha, "_signcorr", corr_cutoff)
filename <- paste0("glmnet", "_", label, "_K", K, "_alpha", alpha, "_signcorr", corr_cutoff)

cat("\nOutput file name:", filename, "\n")

result <- nested_kfold_glmnet_alpha_corr(X, y, K, NMC, alpha=alpha, corr_cutoff=corr_cutoff, typemeas=tmeas, typenorm=c(), covar=c(), fcent=fc, fnorm=fn)

save(result, file=paste0(filename,".Rda"))
writeMat(paste0(filename,".mat"), x=result)
