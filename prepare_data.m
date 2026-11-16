% prepare_data

% parpool('local',8)

dname = 'P:\alahmad\Matlab\Analysis';
NUM = csvread(fullfile(dname,'X.csv')); %#ok<CSVRD> 
dvarnames = cellfun(@(x) sprintf('Delta_%d',x), num2cell(1:500), 'UniformOutput', false);
tvarnames = cellfun(@(x) sprintf('Theta_%d',x), num2cell(1:500), 'UniformOutput', false);
avarnames = cellfun(@(x) sprintf('Alpha_%d',x), num2cell(1:500), 'UniformOutput', false);
bvarnames = cellfun(@(x) sprintf('Beta_%d',x), num2cell(1:500), 'UniformOutput', false);
tblall = array2table(NUM, 'VariableNames', [dvarnames tvarnames avarnames bvarnames {'Group'}]);
writetable(tblall, 'X_with_colnames.csv');

%%
fselname = 'Relieff';   % algorith to select the features
ClassNames = {1 2};     % This is a binomial classification task: labels of the two classes (numeric, categorical or string)
IDC = 2;                % id of critical class
K = 10;                 % Number of folds in K fold cross-validation
NMC = 30;               % Number of Monte Carlo iteration (to get stable results as cross-validation creates random partitions)
NiterBayesOptim = 200;  % Number of Bayesian optimization iterations (used by classifiers that need to optimize hyperparameters)
fcent = true;
fnorm = true;

tic;

% [cvStats_GaussNaiveBayes, honStats_GaussNaiveBayes, colnames, scoresfeat_train_GaussNaiveBayes] = ...
%     class_learn_app_auto(@train_GaussNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_GaussNaiveBayes;

% [cvStats_KernelNaiveBayes, honStats_KernelNaiveBayes, colnames, scoresfeat_train_KernelNaiveBayes] = ...
%     class_learn_app_auto(@train_KernelNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_KernelNaiveBayes;

% [cvStats_WideNeuralNet, honStats_WideNeuralNet, colnames, scoresfeat_train_WideNeuralNet] = ...
%     class_learn_app_auto(@train_WideNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_WideNeuralNet;

% [cvStats_BilayeredNeuralNet, honStats_BilayeredNeuralNet, colnames, scoresfeat_train_BilayeredNeuralNet] = ...
%     class_learn_app_auto(@train_BilayeredNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_BilayeredNeuralNet;

% [cvStats_ANN_BayesianOptim, honStats_ANN_BayesianOptim, colnames, scoresfeat_train_ANN_BayesianOptim] = ...
%     class_learn_app_auto(@train_ANN_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_ANN_BayesianOptim;
% toc_ANN_BayesianOptim = toc


% [cvStats_KSVM_BayesianOptim, honStats_KSVM_BayesianOptim, colnames, scoresfeat_train_KSVM_BayesianOptim] = ...
%     class_learn_app_auto(@train_KSVM_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_KSVM_BayesianOptim;
% toc_KSVM_BayesianOptim = toc

% [cvStats_LogisticReg_BayesianOptim, honStats_LogisticReg_BayesianOptim, colnames, scoresfeat_train_LogisticReg_BayesianOptim] = ...
%     class_learn_app_auto(@train_LogisticReg_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_LogisticReg_BayesianOptim;
% toc_LogisticReg_BayesianOptim = toc

[cvStats_SubspDiscEnsemble, honStats_SubspDiscEnsemble, colnames, scoresfeat_train_SubspDiscEnsemble] = ...
    class_learn_app_auto(@train_SubspDiscEnsemble, fselname, tblall, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
scoresfeat = scoresfeat_train_SubspDiscEnsemble;
toc_SubspDiscEnsemble = toc

xm = mean(scoresfeat,2);
xe = std(scoresfeat,[],2)/sqrt(size(scoresfeat,2));
[xm,ind] = sort(xm,'descend');
xe = xe(ind);
figure; plot_bar_err(xm, xe);

% ind = ind(:)';
% tblsel = tbl(:,[ind(1:nnz(xm>0)) end]);
% writetable(tblsel, 'X_relieff.csv');

%% Save all results to Excel table for ANOVA analyses (MATLAB)

% % type = 'cvStats';
% type = 'honStats';
% 
% methods = {'GaussNaiveBayes' 'KernelNaiveBayes' 'WideNeuralNet' 'BilayeredNeuralNet'};
% tbl = zeros(NMC, length(methods));
% for i = 1:length(colnames)
%     for j = 1:length(methods)
%         tbl(:,j) = eval(sprintf('%s_%s(:,%d)',type,methods{j},i));
%     end
%     tblcell = [methods; num2cell(tbl)];
%     writecell(tblcell, sprintf('X_%s_%s.xlsx',type,colnames{i}));    
% end

%% Save all results to Excel table for ANOVA analyses (SPSS)

% % type = 'cvStats';
% type = 'honStats';
% 
% methods = {'GaussNaiveBayes' 'KernelNaiveBayes' 'WideNeuralNet' 'BilayeredNeuralNet'};
% code = repmat(1:length(methods), [NMC 1]);
% code = code(:);
% 
% tbl = zeros(NMC, length(methods));
% for i = 1:length(colnames)
%     for j = 1:length(methods)
%         tbl(:,j) = eval(sprintf('%s_%s(:,%d)',type,methods{j},i));
%     end
%     tblcell = [methods; num2cell(tbl)];
%     fname = sprintf('X_Matlab_%s_%s.xlsx',type,colnames{i});
%     writecell(tblcell, fname);
%     fname = sprintf('X_SPSS_%s_%s.xlsx',type,colnames{i});
%     writecell(num2cell([tbl(:) code]), fname);
%     writecell(methods,fname,'Sheet',2);
% end
% 
% % NUM = xlsread(fullfile(dirname,'X_Matlab_honStats_accuracy.xlsx'));
% % [p,tbl,stats] = anova1(NUM);
% % [c,m,h,gnames] = multcompare(stats, 'CType', 'hsd');

%% Save all results to Excel table for N-way ANOVA analyses (SPSS)
NMC = 100;

type = 'cvStats';
% type = 'honStats';

colnamestat = ["accuracy" "sensitivity" "specificity" "AUC"];

metall = {'GaussNaiveBayes' 'KernelNaiveBayes' 'WideNeuralNet' 'BilayeredNeuralNet' 'SubspDiscEnsemble' 'KSVM_BayesianOptim' 'GLMNET'};
modall = {'MEG', 'MEGPLANAR'};
norall = {'corrected' 'uncorrected'};
invall = {'Sensor' 'COH', 'MSP', 'EBB', 'LCMV', 'eLORETA'};

code_meth = repmat(1:length(metall), [NMC 1 length(modall) length(norall) length(invall)]);
code_mod = repmat(reshape(1:length(modall),[1 1 length(modall)]), [NMC length(metall) 1 length(norall) length(invall)]);
code_norm = repmat(reshape(1:length(norall),[1 1 1 length(norall)]), [NMC length(metall) length(modall) 1 length(invall)]);
code_invsol = repmat(reshape(1:length(invall),[1 1 1 1 length(invall)]), [NMC length(metall) length(modall) length(norall) 1]);

tblall = zeros(NMC, length(metall), length(modall), length(norall), length(invall));
for iind = 1:length(colnamestat)
    for jind = 1:length(invall)
        for kind = 1:length(norall)
            for lind = 1:length(modall)
                fname = sprintf('results_%s_%s_%s_Relieff_K10.mat', norall{kind}, invall{jind}, modall{lind})
%                 fname = sprintf('results_combined_%s_%s_%s_Relieff_K10.mat', norall{kind}, invall{jind}, modall{lind})
                load(fname);
                for m = 1:length(metall)-1
                    tblall(:,m,lind,kind,jind) = eval(sprintf('%s_%s(:,%d)',type,metall{m},iind));
                end

                fname = sprintf('glmnet_%s_%s_%s_K10.mat', norall{kind}, modall{lind}, invall{jind})
                load(fname, "x");
                switch colnamestat(iind)
                    case "accuracy"
                        if strcmp(type,'honStats')
                            tblall(:,m+1,lind,kind,jind) = x.("Holdout Accuracy");
                        else % cvStats
                            tblall(:,m+1,lind,kind,jind) = x.("CV Accuracy");
                        end
                    case "sensitivity"
                        if strcmp(type,'honStats')
                            tblall(:,m+1,lind,kind,jind) = x.("Holdout Sensitivity");
                        else % cvStats
                            tblall(:,m+1,lind,kind,jind) = x.("CV Sensitivity");
                        end
                    case "specificity"
                        if strcmp(type,'honStats')
                            tblall(:,m+1,lind,kind,jind) = x.("Holdout Specificity");
                        else % cvStats
                            tblall(:,m+1,lind,kind,jind) = x.("CV Specificity");
                        end
                    case "AUC"
                        if strcmp(type,'honStats')
                            tblall(:,m+1,lind,kind,jind) = x.("Holdout AUC");
                        else % cvStats
                            tblall(:,m+1,lind,kind,jind) = x.("CV AUC");
                        end
                end
            end
        end
    end
    fname = sprintf('X_SPSS_Nway_%s_%s.xlsx',type,colnamestat(iind));
    writecell([{'Stat' 'ClassMethods' 'Modalities' 'Normalization' 'InvSolMethods'}; ...
        num2cell([tblall(:) code_meth(:) code_mod(:) code_norm(:) code_invsol(:)])], fname);
    writecell(metall, fname, 'Sheet', 'ClassMethods');
    writecell(modall, fname, 'Sheet', 'Modalities');
    writecell(norall, fname, 'Sheet', 'Normalization');
    writecell(invall, fname, 'Sheet', 'InvSolMethods');
end

% NUM = xlsread(fullfile(dirname,'X_Matlab_honStats_accuracy.xlsx'));
% [p,tbl,stats] = anova1(NUM);
% [c,m,h,gnames] = multcompare(stats, 'CType', 'hsd');