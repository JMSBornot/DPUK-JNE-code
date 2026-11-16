% run_classification_K10_noparfor

% parpool('local',4)

modalities = 'All';
% modalities = 'MEGMAG';
% modalities = 'MEGPLANAR';

% load('P:\alahmad\Matlab\BioFIND-data-paper\features_source_spect.mat', 'A_for_Cov', 'features', 'group_num', 'mri_num', 'type_invsol');
load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_%s_spect.mat',modalities)), ...
    'A_for_Cov', 'features', 'group_num', 'mri_num', 'type_invsol');

inv_method = 'COH';
% inv_method = 'MSP';
% inv_method = 'EBB';

dvarnames = cellfun(@(x) sprintf('Delta_%d',x), num2cell(1:500), 'UniformOutput', false);
tvarnames = cellfun(@(x) sprintf('Theta_%d',x), num2cell(1:500), 'UniformOutput', false);
avarnames = cellfun(@(x) sprintf('Alpha_%d',x), num2cell(1:500), 'UniformOutput', false);
bvarnames = cellfun(@(x) sprintf('Beta_%d',x), num2cell(1:500), 'UniformOutput', false);
gLvarnames = cellfun(@(x) sprintf('GammaL_%d',x), num2cell(1:500), 'UniformOutput', false);
gHvarnames = cellfun(@(x) sprintf('GammaH_%d',x), num2cell(1:500), 'UniformOutput', false);

% fselname = 'Relieff';   % algorithm to select the features
fselname = 'kruskalwallis';

ClassNames = {1 2};     % This is a binomial classification task: labels of the two classes (numeric, categorical or string)
IDC = 2;                % id of critical class
K = 10;                 % Number of folds in K fold cross-validation
NMC = 100;              % Number of Monte Carlo iteration (to get stable results as cross-validation creates random partitions)
NiterBayesOptim = 200;  % Number of Bayesian optimization iterations (used by classifiers that need to optimize hyperparameters)
fcent = true;
fnorm = true;

datcorrection = [true false];

for i = 1:2
    X = features(:,:,strcmp(type_invsol,inv_method));
    if datcorrection(i)
        X = X - A_for_Cov*pinv(A_for_Cov)*X; % Regress out confounds
        fname_output = sprintf('results_corrected_%s_%s_%s_K%d.mat',inv_method,modalities,fselname,K);
    else
        fname_output = sprintf('results_uncorrected_%s_%s_%s_K%d.mat',inv_method,modalities,fselname,K);
    end
    tbl = array2table([X group_num], 'VariableNames', [dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames {'Group'}]);

    clear X features A_for_Cov group_num mri_num

    %% Run classification methods
    disp('Evaluating SubspDiscEnsemble models ...');
    tic;
    [cvStats_SubspDiscEnsemble, honStats_SubspDiscEnsemble, colnames] = ...
        class_learn_app_auto_noparfor(@train_SubspDiscEnsemble, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_SubspDiscEnsemble = toc;
    save(fname_output);

    disp('Evaluating GaussNaiveBayes models ...');
    tic;
    [cvStats_GaussNaiveBayes, honStats_GaussNaiveBayes] = ...
        class_learn_app_auto_noparfor(@train_GaussNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_GaussNaiveBayes = toc;
    save(fname_output);

    disp('Evaluating KernelNaiveBayes models ...');
    tic;
    [cvStats_KernelNaiveBayes, honStats_KernelNaiveBayes] = ...
        class_learn_app_auto_noparfor(@train_KernelNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_KernelNaiveBayes = toc;
    save(fname_output);

    disp('Evaluating WideNeuralNet models ...');
    tic;
    [cvStats_WideNeuralNet, honStats_WideNeuralNet] = ...
        class_learn_app_auto_noparfor(@train_WideNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_WideNeuralNet = toc;
    save(fname_output);

    disp('Evaluating BilayeredNeuralNet models ...');
    tic;
    [cvStats_BilayeredNeuralNet, honStats_BilayeredNeuralNet] = ...
        class_learn_app_auto_noparfor(@train_BilayeredNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_BilayeredNeuralNet = toc;
    save(fname_output);

    disp('Evaluating KSVM models with Bayesian optimization ...');
    tic;
    [cvStats_KSVM_BayesianOptim, honStats_KSVM_BayesianOptim] = ...
        class_learn_app_auto_noparfor(@train_KSVM_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_KSVM_BayesianOptim = toc;
    save(fname_output);

%     disp('Evaluating LogisticReg models with Bayesian optimization ...');
%     tic;
%     [cvStats_LogisticReg_BayesianOptim, honStats_LogisticReg_BayesianOptim] = ...
%         class_learn_app_auto_noparfor(@train_LogisticReg_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
%     toc_LogisticReg_BayesianOptim = toc;
%     save(fname_output);
% 
%     disp('Evaluating ANN models with Bayesian optimization ...');
%     tic;
%     [cvStats_ANN_BayesianOptim, honStats_ANN_BayesianOptim] = ...
%         class_learn_app_auto_noparfor(@train_ANN_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
%     toc_ANN_BayesianOptim = toc;
%     save(fname_output);
end