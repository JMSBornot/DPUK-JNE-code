function [cvStats, honStats, colnames] = honcv(cfunc, datatable, preds, ClassNames, IDC, K, NMC, Niter, fcent, fnorm)
% [cvStats, honStats] = honcv(cfunc, datatable, preds, ClassNames, IDC, K, NMC);
% Hold-out nested cross-validation with Monte Carlo replication
%
% INPUT:
% cfunc - classifier function
% datatable - data
% preds - label of selected predictor variables. Default is 'all'
% ClassNames - labels of the two classes
% IDC - id of critical class
% K - number of K folds
% NMC - Number of Monte Carlo simulations
% Niter - Number of Bayesian optimization iterations
% fcent = true if data need to be centered
% fnorm = true if data need to be normalized
%
% OUTPUT:
% cvStats  - cross-validatation statistics for each Monte Carlo replication. Dimension: NMC x 4.
%            Columns are accuracy, sensitivity, specificity, and area under curve, in this order.
% honStats - holdout samples statistics for each Monte Carlo replication. Dimension: NMC x 3.
%            Columns are accuracy, sensitivity and specificity in this order.
% colnames - names of calculated statistics

N = size(datatable,1);
cvStats = zeros(NMC,4);
honStats = zeros(NMC,4);
colnames = {'accuracy', 'sensitivity', 'specificity', 'AUC'};
for inmc = 1:NMC
    if (mod(inmc,100) == 0)
        disp([inmc NMC]);
    end
    cv  = cvpartition(datatable.Group,'k',K);
    acc = 0;
    sens = 0;
    spec = 0;
    AUC = 0;
    AUCho = 0;
    ypred = zeros(N,1);
    for k = 1:K
        fprintf('\n\nk=%d of %d folds. Monte Carlo iteration %d of %d ... \n\n', k, K, inmc, NMC);
        
        % Extract data for selected fold
        indho = find(cv.test(k));
        ind = setdiff(1:N,indho);
        X = table2array(datatable(ind,preds));
        Y = datatable.Group(ind);
        Xho = table2array(datatable(indho,preds));
        Yho = datatable.Group(indho);
        if fcent
          tmp = mean(X);
            X = X-tmp;
            Xho = Xho-tmp;
        end
        if fnorm
            tmp = sqrt(sum(X.^2));
            X = X./tmp;
            Xho = Xho./tmp;
        end
        
        % train classifier and calculate its statistics
        mdl = feval(cfunc,X,Y,Niter,K-1);
        %[~,score] = resubPredict(mdl);
        [yfit,score] = mdl.predict(X);
        if isnumeric(ClassNames{IDC})
            resp = (Y == ClassNames{IDC});
        else
            resp = strcmp(Y,ClassNames{IDC});
        end
        [~,~,~,tmp] = perfcurve(resp, score(:,IDC), 'true');
        AUC = AUC + tmp;
      
        if isnumeric(ClassNames{IDC})
            acc = acc + nnz(Y == yfit)/length(yfit);
            flag = (Y == ClassNames{IDC});
            sens = sens + nnz(flag & (yfit == ClassNames{IDC}))/nnz(flag);
            spec = spec + nnz(~flag & (yfit == ClassNames{3-IDC}))/nnz(~flag);
        else
            acc = acc + nnz(strcmp(Y,yfit))/length(yfit);
            flag = strcmp(Y,ClassNames{IDC});
            sens = sens + nnz(flag & strcmp(yfit,ClassNames{IDC}))/nnz(flag);
            spec = spec + nnz(~flag & strcmp(yfit, ClassNames{3-IDC}))/nnz(~flag);
        end
        
        % evaluate classifier on holdout samples
        [ypred(indho),score] = mdl.predict(Xho);
        if isnumeric(ClassNames{IDC})
            resp = (Yho == ClassNames{IDC});
        else
            resp = strcmp(Yho,ClassNames{IDC});
        end
        [~,~,~,tmp] = perfcurve(resp, score(:,IDC), 'true');
        AUCho = AUCho + tmp;
    end
    % summarize stats for cross-validation
    cvStats(inmc,:) = [acc sens spec AUC]/K;
    
    % summarize stats for holdout samples
    [C,~] = confusionmat(datatable.Group, ypred);
    honStats(inmc,1) = sum(diag(C))/sum(C(:));                                      % prediction accuracy
    if isnumeric(ClassNames{IDC})
        flag = (datatable.Group == ClassNames{IDC});
        honStats(inmc,2) = nnz(flag & (ypred == ClassNames{IDC}))/nnz(flag);         % sensitivity
        honStats(inmc,3) = nnz((~flag) & (ypred == ClassNames{3-IDC}))/nnz(~flag);    % specificity
    else
        flag = strcmp(datatable.Group, ClassNames{IDC});
        honStats(inmc,2) = nnz(flag & strcmp(ypred,ClassNames{IDC}))/nnz(flag);         % sensitivity
        honStats(inmc,3) = nnz(~flag & strcmp(ypred, ClassNames{3-IDC}))/nnz(~flag);    % specificity
    end
    honStats(inmc,4) = AUCho/K;
end