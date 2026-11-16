nested_kfold_glmnet_alpha_corr <- function(X, y, K, NMC, alpha=1, corr_cutoff=0, typemeas="auc", typenorm=c(), covar=c(), fcent=TRUE, fnorm=TRUE) {
  # K        - K fold cross-validation
  # NMC      - Number of Monte Carlo iterations
  # alpha    - hyperparameter to control regularization between L1 and L2 norms
  # corr_cutoff - correlation cutoff to preselect predictor and their sign constraints
  # typemeas - either "class" or "auc"
  # typenorm - either "residuals", "zscores", or empty(c()) 
  
  # settings:
  cat("\n Input settings:",
      "\n- GLMNET's alpha is", alpha,
      "\n- GLMNET's sign constraints given by correlation cutoff", corr_cutoff,
      "\n- Performance measure (typemeas) is", typemeas,
      "\n- Data harmonization function (typenorm) is", typenorm,
      "\n- Data centering option (fcent) is", fcent,
      "\n- Data standard deviation normalization option (fnorm) is", fnorm, "\n")
  
  if (missing(X))
    stop("X must be provided as the predictors matrix.")
  if (missing(y))
    stop("y must be provided as the response vector.")
  if (missing(K))
    stop("K must be provided as the number of K folds (cross-validation analysis).")
  if (missing(NMC))
    stop("NMC must be provided as the number of Monte Carlo iterations.")
  
  if ((typemeas != "auc") && (typemeas != "class") && (typemeas != "mse") && (typemeas != "mae") && (typemeas != "deviance"))
    stop("typemeas must be any of the following: auc, class, mse, mae, or deviance. See glmnet help for more info.")
  
  if (!is.null(typenorm)) {
    if (is.null(covar))
      stop("covariates must have been provided for the normalization process.")
    if ((typenorm != "residuals") && (typenorm != "zscores"))
      stop("typenorm must be empty or any of the following values: residuals or zcores")
  }
  
  # sign constraints according to correlation between predictors and response variables
  kXy <- cor(X, y, method="pearson")
  png(file="correlation.png", width=1200, height=800)
  plot(kXy, main="Correlation(X,y)", xlab="Predictor", ylab="Value")
  dev.off()
  
  print(ncol(X))
  print(sum(abs(kXy) >= corr_cutoff))
  print(sum(abs(kXy) < corr_cutoff))
  
  X <- X[, abs(kXy) >= corr_cutoff]
  kXy <- kXy[abs(kXy) >= corr_cutoff]
  print(ncol(X))
  
  limL <- rep(-Inf, ncol(X))
  limH <- rep(Inf, ncol(X))
  limL[kXy >= corr_cutoff] <- 0
  limH[kXy <= -corr_cutoff] <- 0
  
  # auxiliar algebraic handle functions
  func_centering <- function(x,c) x-c
  func_vecstdnorm <- function(x) sqrt(mean(x*x))
  func_rescale <- function(x,s) x/s
  
  # output vars
  acc_train <- matrix(0,1,NMC)
  bac_train <- matrix(0,1,NMC)
  sen_train <- matrix(0,1,NMC)
  spc_train <- matrix(0,1,NMC)
  ppv_train <- matrix(0,1,NMC)
  npv_train <- matrix(0,1,NMC)
  auc_train <- matrix(0,1,NMC)
  acc_holdout <- matrix(0,1,NMC)
  bac_holdout <- matrix(0,1,NMC)
  sen_holdout <- matrix(0,1,NMC)
  spc_holdout <- matrix(0,1,NMC)
  ppv_holdout <- matrix(0,1,NMC)
  npv_holdout <- matrix(0,1,NMC)
  auc_holdout <- matrix(0,1,NMC)
  beta <- matrix(0,ncol(X)+1,K*NMC)
  lambda_min <- matrix(0,K,NMC)
  gamma_min <- matrix(0,K,NMC)
  
  # holdout predictions
  ypho <- rep(0,length(y))
  
  # relaxed glmnet input
  gvec <- seq(from=0, to=1, by=0.1)
  
  # Main
  for (it in 1:NMC) {
    cat("\n Monte-Carlo iteration", it, "of", NMC, "\n")
    
    folds <- createFolds(1:length(y), K);
    
    acc <- 0
    bac <- 0
    sen <- 0
    spc <- 0
    ppv <- 0
    npv <- 0
    auc <- 0
    
    for (j in 1:K) {
      cat("k =", j, "of", K, "fold\n")
      
      ind <- folds[[j]]
      Xtr <- X[-ind, ]
      ytr <- y[-ind]
      Xho <- X[ind, ]
      
      # data preprocessing
      print("data preprocessing...")
      
      if (!is.null(typenorm)) {
        dattr <- data.frame(x1=covar$Age[-ind], x2=covar$Gender[-ind], x3=covar$TIV[-ind],
                            x4=covar$Age[-ind]*covar$Gender[-ind],
                            x5=covar$Age[-ind]*covar$TIV[-ind],
                            x6=covar$Gender[-ind]*covar$TIV[-ind])
        datho <- data.frame(x1=covar$Age[ind], x2=covar$Gender[ind], x3=covar$TIV[ind],
                            x4=covar$Age[ind]*covar$Gender[ind],
                            x5=covar$Age[ind]*covar$TIV[ind],
                            x6=covar$Gender[ind]*covar$TIV[ind])
        
        if (typenorm == "residuals") {
          for (i in 1:ncol(X)) {
            # fit model to train data and only to controls
            dattr$y <- Xtr[,i]
            lmodel <- lm(y ~ x1 + x2 + x3 + x4 + x5 + x6, data=dattr[ytr==0,])
            # adjust train data
            pp <- predict(lmodel, dattr, interval="prediction", level=0.95)
            Xtr[,i] <- Xtr[,i] - pp[,1]
            # adjust holdout data
            pp <- predict(lmodel, datho, interval="prediction", level=0.95)
            Xho[,i] <- Xho[,i] - pp[,1]
          }
        }
        
        if (typenorm == "zscores") {
          for (i in 1:ncol(X)) {
            # fit model to train data and only to controls
            dattr$y <- Xtr[,i]
            lmodel <- lm(y ~ x1 + x2 + x3 + x4 + x5 + x6, data=dattr[ytr==0,])
            # adjust train data
            pp <- predict(lmodel, dattr, interval="prediction", level=0.95)
            sgm <- (pp[,3] - pp[,1])/1.96
            Xtr[,i] <- (Xtr[,i] - pp[,1])/sgm
            # adjust holdout data
            pp <- predict(lmodel, datho, interval="prediction", level=0.95)
            sgm <- (pp[,3] - pp[,1])/1.96
            Xho[,i] <- (Xho[,i] - pp[,1])/sgm
          }
        }
      }
      else {
        if (fnorm) {
          # calculate mean for the train data only
          cm <- matrix(colMeans(Xtr), ncol=ncol(Xtr))
          Xtr <- t(apply(Xtr, 1, func_centering, cm))
          Xho <- t(apply(Xho, 1, func_centering, cm))
        }
        
        if (fcent) {
          # calculate scale for the train data only
          cs <- matrix(apply(Xtr, 2, func_vecstdnorm), ncol=ncol(Xtr))
          Xtr <- t(apply(Xtr, 1, func_rescale, cs))
          Xho <- t(apply(Xho, 1, func_rescale, cs))
        }
      }
      
      # running glmnet
      print("Running glmnet...")
      
      cvfit <- cv.glmnet(Xtr, ytr, family="binomial", alpha=alpha,
                         type.measure=typemeas, lower.limits=limL, upper.limits=limH,
                         keep=TRUE, nfolds=K-1, relax=TRUE, path=TRUE, gamma=gvec)
      
      # calculate stats for training data
      print("Calculate stats...")
      
      yptr <- predict(cvfit, newx=Xtr, s=cvfit$relaxed$lambda.min, gamma=cvfit$relaxed$gamma.min)
      ypho[ind] <- predict(cvfit, newx=Xho, s=cvfit$relaxed$lambda.min, gamma=cvfit$relaxed$gamma.min)
      
      xtab <- table(pred=0+(yptr>0), truth=ytr)
      cnf <- confusionMatrix(xtab, positive="1")
      acc <- acc + (xtab[1,1] + xtab[2,2])/(xtab[1,1] + xtab[1,2] + xtab[2,1] + xtab[2,2])
      bac <- bac + cnf$byClass["Balanced Accuracy"]
      sen <- sen + cnf$byClass["Sensitivity"]
      spc <- spc + cnf$byClass["Specificity"]
      ppv <- ppv + cnf$byClass["Pos Pred Value"]
      npv <- npv + cnf$byClass["Neg Pred Value"]
      fit <- roc(response=ytr, predictor=yptr)
      auc <- auc + fit$auc
      
      # save relax.glmnet coefficients
      tmp <- predict(cvfit, type="coef", s=cvfit$relaxed$lambda.min, gamma=cvfit$relaxed$gamma.min)
      beta[,(it-1)*K+j] <- tmp[,1]
      
      # save 'optimal' hyperparameter values
      lambda_min[j,it] <- cvfit$relaxed$lambda.min
      gamma_min[j,it] <- cvfit$relaxed$gamma.min
    }
    acc_train[it] = acc/K
    bac_train[it] = bac/K
    sen_train[it] = sen/K
    spc_train[it] = spc/K
    ppv_train[it] = ppv/K
    npv_train[it] = npv/K
    auc_train[it] = auc/K
    
    cat("acc_avg_train = ", acc_train[it], "\n")
    cat("bac_avg_train = ", bac_train[it], "\n")
    cat("sen_avg_train = ", sen_train[it], "\n")
    cat("spc_avg_train = ", spc_train[it], "\n")
    cat("ppv_avg_train = ", ppv_train[it], "\n")
    cat("npv_avg_train = ", npv_train[it], "\n")
    cat("auc_avg_train = ", auc_train[it], "\n")
    
    # calculate stats for holdout data
    xtab <- table(pred=0+(ypho>0), truth=y)
    cnf <- confusionMatrix(xtab, positive="1")
    acc_holdout[it] <- (xtab[1,1] + xtab[2,2])/(xtab[1,1] + xtab[1,2] + xtab[2,1] + xtab[2,2])
    bac_holdout[it] <- cnf$byClass["Balanced Accuracy"]
    sen_holdout[it] <- cnf$byClass["Sensitivity"]
    spc_holdout[it] <- cnf$byClass["Specificity"]
    ppv_holdout[it] <- cnf$byClass["Pos Pred Value"]
    npv_holdout[it] <- cnf$byClass["Neg Pred Value"]
    fit <- roc(response=y, predictor=ypho)
    auc_holdout[it] <- fit$auc
    
    cat("acc_avg_holdout = ", acc_holdout[it], "\n")
    cat("bac_avg_holdout = ", bac_holdout[it], "\n")
    cat("sen_avg_holdout = ", sen_holdout[it], "\n")
    cat("spc_avg_holdout = ", spc_holdout[it], "\n")
    cat("ppv_avg_holdout = ", ppv_holdout[it], "\n")
    cat("npv_avg_holdout = ", npv_holdout[it], "\n")
    cat("auc_avg_holdout = ", auc_holdout[it], "\n")
  }
  
  # Output
  cat("Results are output as a list.\n")
  result <- list("CV Accuracy" = acc_train, "CV Balanced Acc" = bac_train,
                 "CV Sensitivity" = sen_train, "CV Specificity" = spc_train,
                 "CV PPV" = ppv_train, "CV NPV" = npv_train, "CV AUC" = auc_train,
                 "Holdout Accuracy" = acc_holdout, "Holdout Balanced Acc" = bac_holdout,
                 "Holdout Sensitivity" = sen_holdout, "Holdout Specificity" = spc_holdout,
                 "Holdout PPV" = ppv_holdout, "Holdout NPV" = npv_holdout, "Holdout AUC" = auc_holdout,
                 "Coefficients" = beta, "Lambda Min" = lambda_min, "Gamma Min" = gamma_min)
  
  return(result)
}