library(readxl)
library(dplyr)
library(glmnet)
library(caret)
library(ROCR)
library(pROC)
#library(StatsTools) # my own library

source("nested_kfold_relaxed_glmnet.R")

# tmeas <- "class"
tmeas <- "auc"
# tnorm <- "residuals"
tnorm <- "zscores"
# tnorm <- c()
fc <- TRUE
fn <- TRUE

stats_label <- "aparcaseg"

stats <- read_excel(paste0("S:/0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B/Freesurfer/Classification Script/",
                           "Combine_", stats_label, "_proc.xlsx"))

# Concatenate the data for CN and MCI groups
isCN <- (stats$Group == 1)
isMCI <- (stats$Group == 2)
ind <- seq(-1,-5,-1)
X <- rbind(as.matrix(stats[isCN, ind]), as.matrix(stats[isMCI, ind]))

# Binomial group variable (CN=0 and MCI=1)
y <- c(rep(0, sum(isCN)), rep(1, sum(isMCI)))

# Covariates
Age <- rbind(as.matrix(stats$Age[isCN]), as.matrix(stats$Age[isMCI]))
Gender <- 1-rbind(as.matrix(stats$Gender[isCN]==1), as.matrix(stats$Gender[isMCI]==1)) # male's code=0
TIV <- rbind(as.matrix(stats$eTIV[isCN]), as.matrix(stats$eTIV[isMCI]))
cov <- data.frame(Age, Gender, TIV)

K <- 10

if (!is.null(tnorm)) {
  filename_output <- paste0("results_relaxed", "_", stats_label, "_", tmeas, "_", tnorm, "_K", K, ".Rda")
} else {
  filename_output <- paste0("results_relaxed", "_", stats_label, "_", tmeas, "_fcent_", fc, "_fnorm_",  fn, "_K", K, ".Rda")
}
cat("\n Output file name:", filename_output, "\n")

NMC <- 5
#result <- nested_kfold_relaxed_glmnet(X, y, K, NMC, typemeas=tmeas, typenorm=tnorm, covar=cov)
result <- nested_kfold_relaxed_glmnet(X, y, K, NMC, typemeas=tmeas, typenorm=tnorm, covar=cov)
#result <- nested_kfold_relaxed_glmnet(X, y, K, NMC, typemeas=tmeas, typenorm=tnorm, covar=cov)
#result <- nested_kfold_relaxed_glmnet(X, y, K, NMC, typemeas=tmeas, typenorm=tnorm, covar=c(), fcent=fc, fnorm=fn)
print(result)

save(result, file=filename_output)
# load("results_auc_residuals.Rda")