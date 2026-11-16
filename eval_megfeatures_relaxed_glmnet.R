#library(readxl)
library(R.matlab)

library(dplyr)
library(glmnet)
library(caret)
library(ROCR)
library(pROC)

source("nested_kfold_relaxed_glmnet.R")

args <- commandArgs(trailingOnly=TRUE)
Nargs <- length(args)
cat("Number of input arguments:", Nargs, "\n")

# Label for stats table
#stats_label <- args[1]
label <- args[1]
# K for K-fold cross-validation
K <- as.integer(args[2])
# Number of Monte Carlo replications
NMC <- as.integer(args[3])
# type of error measure
tmeas <- args[4]
# GLMNET's alpha
alpha <- as.numeric(args[5])

fc <- TRUE
fn <- TRUE

#features_uncorrected_MEG_eLORETA.xlsx
#stats <- read_excel(paste0("P:/alahmad/Matlab/BioFIND-data-paper/", "features_", stats_label, ".xlsx"))

# Concatenate the data for CN and MCI groups
#isCN <- (stats$Group == 1)
#isMCI <- (stats$Group == 2)
#ind <- -1
#X <- rbind(as.matrix(stats[isCN, ind]), as.matrix(stats[isMCI, ind]))

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

filename_output <- paste0("glmnet_relaxed", "_", label, "_K", K, "_alpha", alpha, ".Rda")

cat("\nOutput file name:", filename_output, "\n")

result <- nested_kfold_relaxed_glmnet(X, y, K, NMC, alpha=alpha, typemeas=tmeas, typenorm=c(), covar=c(), fcent=fc, fnorm=fn)

save(result, file=filename_output)