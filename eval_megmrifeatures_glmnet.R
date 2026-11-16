library(readxl)
library(dplyr)
library(glmnet)
library(caret)
library(ROCR)
library(pROC)

source("nested_combined_kfold_glmnet.R")

args <- commandArgs(trailingOnly=TRUE)
Nargs <- length(args)
cat("Number of input arguments:", Nargs, "\n")

# Label for stats table
stats_label <- args[1]
# K for K-fold cross-validation
K <- as.integer(args[2])
# Number of Monte Carlo replications
NMC <- as.integer(args[3])
# type of error measure
tmeas <- args[4]

fc <- TRUE
fn <- TRUE

#features_uncorrected4comb_MEG_COH.xlsx
#stats_label <- "MEG_Sensor"
#stats_label <- "MEG_COH"
#stats <- read_excel(paste0("features_uncorrected4comb_", stats_label, ".xlsx"))

#features_uncorrected4allcomb_COH.xlsx
#stats_label <- "Sensor"
#stats_label <- "COH"
stats <- read_excel(paste0("features_uncorrected4allcomb_", stats_label, ".xlsx"))

# Concatenate the data for CN and MCI groups
isCN <- (stats$Group == 1)
isMCI <- (stats$Group == 2)
ind <- -1
Xmeg <- rbind(as.matrix(stats[isCN, ind]), as.matrix(stats[isMCI, ind]))

# Binomial group variable (CN=0 and MCI=1)
y <- c(rep(0, sum(isCN)), rep(1, sum(isMCI)))

stats <- read_excel("Combine_aparcaseg_proc.xlsx")
ind <- seq(-1,-5,-1)
Xmri <- rbind(as.matrix(stats[isCN, ind]), as.matrix(stats[isMCI, ind]))

# Covariates for z-scores correction
Age <- rbind(as.matrix(stats$Age[isCN]), as.matrix(stats$Age[isMCI]))
Gender <- 1-rbind(as.matrix(stats$Gender[isCN]==1), as.matrix(stats$Gender[isMCI]==1)) # male's code=0
TIV <- rbind(as.matrix(stats$eTIV[isCN]), as.matrix(stats$eTIV[isMCI]))
cov <- data.frame(Age, Gender, TIV)

#filename_output <- paste0("glmnet_combined_uncorrected", "_", stats_label, "_K", K, ".Rda")
filename_output <- paste0("glmnet_allcombined_uncorrected", "_", stats_label, "_K", K, ".Rda")

cat("\nOutput file name:", filename_output, "\n")

result <- nested_combined_kfold_glmnet(Xmeg, Xmri, y, K, NMC, typemeas=tmeas, typenorm="zscores", covar=cov, fcent=1, fnorm=1)

save(result, file=filename_output)
