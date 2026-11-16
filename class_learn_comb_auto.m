function [cvStats, honStats, colnames, scoresfeat] = ...
    class_learn_comb_auto(cfunc, fsname, tbl, tblMEG, ClassNames, IDC, K, NMC, Niter, fcent, fnorm, typenorm, covarnames)

if exist('typenorm','var') && ~isempty(typenorm)
    if ~exist('covarnames','var')
        covarnames = {'Age', 'Gender', 'TIV'};
    end
    if ~ismember(typenorm,{'residuals', 'zscores'})
        error('The alternative data harmonization procedures are either ''residuals'' or ''zscores''.');
    end
else
    typenorm = [];
end

if ~isempty(typenorm)
    Xall = table2array(removevars(tbl,union('Group',covarnames)));
    Covall = table2array(tbl(:,covarnames));
else
    Xall = table2array(removevars(tbl,'Group'));    
    Covall = [];
end
Yall = tbl.Group;
XallMEG = table2array(removevars(tblMEG,'Group'));

Nobs = length(Yall);
Nvars = size(Xall,2) + size(XallMEG,2);
cvStats_cell = cell(NMC,1);
honStats_cell = cell(NMC,1);
scoresfeat_cell = cell(1,NMC);
colnames = {'accuracy', 'sensitivity', 'specificity', 'AUC'};

parfor inmc = 1:NMC
    disp([inmc NMC]);
    
    cv  = cvpartition(Yall,'k',K);
    % cvStats = zeros(1,4);
    honStats = zeros(1,4);          % not necessary to initialize value, just need to separate memory
    scoresfeat = zeros(Nvars,1);    % initialize to zero
    acc = 0;
    sens = 0;
    spec = 0;
    AUC = 0;
    AUCho = 0;
    ypred = zeros(Nobs,1);
    for k = 1:K
        % Extract data for selected fold
        flagtrain = cv.training(k);
        flagho = cv.test(k);
        X = Xall(flagtrain,:); %#ok<PFBNS> 
        Y = Yall(flagtrain);
        XMEG = XallMEG(flagtrain,:);
        Xho = Xall(flagho,:);
        Yho = Yall(flagho);
        XMEGho = XallMEG(flagho,:);

        %% Normalizing data
        if ~isempty(typenorm)
            Cov = Covall(flagtrain,:);
            Covho = Covall(flagho,:);

            if isnumeric(ClassNames{IDC}) %#ok<PFBNS>
                flag = (Y == ClassNames{IDC});
            else
                flag = strcmp(Y,ClassNames{IDC});
            end
            flag = ~flag;
            for i = 1:size(X,2)
                mdl = fitlm(Cov(flag,:), X(flag,i), 'interactions');

                [fitted,confint] = predict(mdl, Cov, 'Prediction', 'observation');
                if strcmpi(typenorm,'residuals')
                    X(:,i) = X(:,i) - fitted;
                elseif strcmpi(typenorm,'zscores')
                    std = (confint(:,2) - fitted)/1.96;
                    X(:,i) = (X(:,i) - fitted)./std;
                end

                [fitted,confint] = predict(mdl, Covho, 'Prediction', 'observation');
                if strcmpi(typenorm,'residuals')
                    Xho(:,i) = Xho(:,i) - fitted;
                elseif strcmpi(typenorm,'zscores')
                    std = (confint(:,2) - fitted)/1.96;
                    Xho(:,i) = (Xho(:,i) - fitted)./std;
                end
            end                       
        else
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
        end

        if fcent
            tmp = mean(XMEG);
            XMEG = XMEG-tmp;
            XMEGho = XMEGho-tmp;
        end
        if fnorm
            tmp = sqrt(sum(XMEG.^2));
            XMEG = XMEG./tmp;
            XMEGho = XMEGho./tmp;
        end

        %% Concat MRI and MEG features in this order
        X = [X XMEG];
        Xho = [Xho XMEGho];

        %% Selecting features
        switch lower(fsname)
            case 'mrmr'
                [~,scores] = fscmrmr(X,Y);
            case 'chi2'
                [~,scores] = fscchi2(X,Y);
            case 'relieff'
                [~,scores] = relieff(X,Y,10);
            case 'anova'
                p = zeros(Nvars,1);
                for i = 1:Nvars
                    p(i) = anova1(X(:,i),Y,'off');
                end
                scores = -log(p);
            case 'kruskalwallis'
                p = zeros(Nvars,1);
                for i = 1:Nvars
                    p(i) = kruskalwallis(X(:,i),Y,'off');
                end
                scores = -log(p);
        end
        scoresfeat = scoresfeat + scores(:);

        % sort scores in descending order and select features according to
        % each method cutoff
        [scores,indfeatsel] = sort(scores,'descend');
        switch lower(fsname)
            case 'mrmr'
                indfeatsel = indfeatsel(1:nnz(scores>0));
            case 'chi2'
                
            case 'relieff'
                indfeatsel = indfeatsel(1:nnz(scores>0));
            case 'anova'
                
            case 'kruskalwallis'
%                 pcutoff = -log(0.1/Nvars);
                pcutoff = -log(0.001);
                indfeatsel = indfeatsel(1:nnz(scores>pcutoff));
        end
        X = X(:,indfeatsel);
        Xho = Xho(:,indfeatsel);
        fprintf('No. selected features = %d\n', length(indfeatsel)); drawnow;
        
        %% Train classifier and calculate performance measures
        mdl = feval(cfunc,X,Y,Niter,K-1);
        [yfit,prob] = mdl.predict(X);
        if isnumeric(ClassNames{IDC})
            resp = (Y == ClassNames{IDC});
        else
            resp = strcmp(Y,ClassNames{IDC});
        end
        [~,~,~,tmp] = perfcurve(resp, prob(:,IDC), 'true');
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
        [ypred(flagho),prob] = mdl.predict(Xho);
        if isnumeric(ClassNames{IDC})
            resp = (Yho == ClassNames{IDC});
        else
            resp = strcmp(Yho,ClassNames{IDC});
        end
        [~,~,~,tmp] = perfcurve(resp, prob(:,IDC), 'true');
        AUCho = AUCho + tmp;
    end
    % summarize stats for cross-validation
    cvStats = [acc sens spec AUC]/K;
    
    % summarize stats for holdout samples
    [C,~] = confusionmat(Yall, ypred);
    honStats(1) = sum(diag(C))/sum(C(:));                                      % prediction accuracy
    if isnumeric(ClassNames{IDC})
        flag = (Yall == ClassNames{IDC});
        honStats(2) = nnz(flag & (ypred == ClassNames{IDC}))/nnz(flag);         % sensitivity
        honStats(3) = nnz((~flag) & (ypred == ClassNames{3-IDC}))/nnz(~flag);    % specificity
    else
        flag = strcmp(Yall, ClassNames{IDC});
        honStats(2) = nnz(flag & strcmp(ypred,ClassNames{IDC}))/nnz(flag);         % sensitivity
        honStats(3) = nnz(~flag & strcmp(ypred, ClassNames{3-IDC}))/nnz(~flag);    % specificity
    end
    honStats(4) = AUCho/K;

    cvStats_cell{inmc} = cvStats;
    honStats_cell{inmc} = honStats;
    scoresfeat_cell{inmc} = scoresfeat;
end
cvStats = cell2mat(cvStats_cell);
honStats = cell2mat(honStats_cell);
scoresfeat = cell2mat(scoresfeat_cell)/K;