% run_classification_K5

% parpool('local',4)

dname = 'P:\alahmad\Matlab\Analysis';
NUM = csvread(fullfile(dname,'X.csv')); %#ok<CSVRD> 
dvarnames = cellfun(@(x) sprintf('Delta_%d',x), num2cell(1:500), 'UniformOutput', false);
tvarnames = cellfun(@(x) sprintf('Theta_%d',x), num2cell(1:500), 'UniformOutput', false);
avarnames = cellfun(@(x) sprintf('Alpha_%d',x), num2cell(1:500), 'UniformOutput', false);
bvarnames = cellfun(@(x) sprintf('Beta_%d',x), num2cell(1:500), 'UniformOutput', false);
tbl = array2table(NUM, 'VariableNames', [dvarnames tvarnames avarnames bvarnames {'Group'}]);
writetable(tbl, 'X_with_colnames.csv');

clear NUM

%%
fselname = 'Relieff';   % algorith to select the features
ClassNames = {1 2};     % This is a binomial classification task: labels of the two classes (numeric, categorical or string)
IDC = 2;                % id of critical class
K = 5;                 % Number of folds in K fold cross-validation
NMC = 100;                % Number of Monte Carlo iteration (to get stable results as cross-validation creates random partitions)
NiterBayesOptim = 200;  % Number of Bayesian optimization iterations (used by classifiers that need to optimize hyperparameters)
fcent = true;
fnorm = true;

% disp('Evaluating GaussNaiveBayes models ...');
% tic;
% [cvStats_GaussNaiveBayes, honStats_GaussNaiveBayes, colnames] = ...
%     class_learn_app_auto(@train_GaussNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% scoresfeat = scoresfeat_train_GaussNaiveBayes;
% toc_GaussNaiveBayes = toc;
% save results_K5
% 
% disp('Evaluating KernelNaiveBayes models ...');
% tic;
% [cvStats_KernelNaiveBayes, honStats_KernelNaiveBayes] = ...
%     class_learn_app_auto(@train_KernelNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% toc_KernelNaiveBayes = toc;
% save results_K5
% 
% disp('Evaluating WideNeuralNet models ...');
% tic;
% [cvStats_WideNeuralNet, honStats_WideNeuralNet] = ...
%     class_learn_app_auto(@train_WideNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% toc_WideNeuralNet = toc;
% save results_K5
% 
% disp('Evaluating BilayeredNeuralNet models ...');
% tic;
% [cvStats_BilayeredNeuralNet, honStats_BilayeredNeuralNet] = ...
%     class_learn_app_auto(@train_BilayeredNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% toc_BilayeredNeuralNet = toc;
% save results_K5
% 
% disp('Evaluating KSVM models with Bayesian optimization ...');
% tic;
% [cvStats_KSVM_BayesianOptim, honStats_KSVM_BayesianOptim] = ...
%     class_learn_app_auto(@train_KSVM_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% toc_KSVM_BayesianOptim = toc;
% save results_K5

disp('Evaluating LogisticReg models with Bayesian optimization ...');
tic;
[cvStats_LogisticReg_BayesianOptim, honStats_LogisticReg_BayesianOptim] = ...
    class_learn_app_auto(@train_LogisticReg_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
toc_LogisticReg_BayesianOptim = toc;
save results_K5

disp('Evaluating ANN models with Bayesian optimization ...');
tic;
[cvStats_ANN_BayesianOptim, honStats_ANN_BayesianOptim] = ...
    class_learn_app_auto(@train_ANN_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
toc_ANN_BayesianOptim = toc;
save results_K5

%% Save all results to Excel table for ANOVA analyses (SPSS)

type = 'cvStats';
% type = 'honStats';

methods = {'GaussNaiveBayes' 'KernelNaiveBayes' 'WideNeuralNet' 'BilayeredNeuralNet' 'KSVM_BayesianOptim' 'LogisticReg_BayesianOptim' 'ANN_BayesianOptim'};
code = repmat(1:length(methods), [NMC 1]);
code = code(:);

tbl = zeros(NMC, length(methods));
for i = 1:length(colnames)
    for j = 1:length(methods)
        tbl(:,j) = eval(sprintf('%s_%s(:,%d)',type,methods{j},i));
    end
    tblcell = [methods; num2cell(tbl)];
    fname = sprintf('X_Matlab_K5_%s_%s.xlsx',type,colnames{i});
    writecell(tblcell, fname);
    fname = sprintf('X_SPSS_K5_%s_%s.xlsx',type,colnames{i});
    writecell(num2cell([tbl(:) code]), fname);
    writecell(methods,fname,'Sheet',2);
end

% NUM = xlsread(fullfile(dirname,'X_Matlab_honStats_accuracy.xlsx'));
% [p,tbl,stats] = anova1(NUM);
% [c,m,h,gnames] = multcompare(stats, 'CType', 'hsd');