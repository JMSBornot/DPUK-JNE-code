function run_classification_K10(modalities, type_data)

% parpool('local',4)

% % modalities = 'All';
% modalities = 'MEG';
% % modalities = 'MEGPLANAR';
% 
% % load('P:\alahmad\Matlab\BioFIND-data-paper\features_source_spect.mat', 'A_for_Cov', 'features', 'group_num', 'mri_num', 'type_invsol');
% 
% % type_data = 'COH';
% % type_data = 'MSP';
% % type_data = 'EBB';
% type_data = 'Sensor';

if strcmp(type_data,'Sensor')
    if strcmp(modalities,'All')
        Nfeat = 306;
    elseif strcmp(modalities,'MEG')
        Nfeat = 102;
    elseif strcmp(modalities,'MEGPLANAR')
        Nfeat = 204;
    else
        Nfeat = -1;
    end
else
    Nfeat = 500;
end

dvarnames = cellfun(@(x) sprintf('Delta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
tvarnames = cellfun(@(x) sprintf('Theta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
avarnames = cellfun(@(x) sprintf('Alpha_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
bvarnames = cellfun(@(x) sprintf('Beta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
gLvarnames = cellfun(@(x) sprintf('GammaL_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
gHvarnames = cellfun(@(x) sprintf('GammaH_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);

fselname = 'Relieff';   % algorithm to select the features
% fselname = 'kruskalwallis';

%%
ClassNames = {1 2};     % This is a binomial classification task: labels of the two classes (numeric, categorical or string)
IDC = 2;                % id of critical class
K = 10;                 % Number of folds in K fold cross-validation
NMC = 100;              % Number of Monte Carlo iteration (to get stable results as cross-validation creates random partitions)
NiterBayesOptim = 200;  % Number of Bayesian optimization iterations (used by classifiers that need to optimize hyperparameters)
fcent = true;
fnorm = true;

datcorrection = [true false];

for i = 1:2
    if datcorrection(i)
        fname_output = sprintf('results_corrected_%s_%s_%s_K%d.mat',type_data,modalities,fselname,K);
    else
        fname_output = sprintf('results_uncorrected_%s_%s_%s_K%d.mat',type_data,modalities,fselname,K);
    end
    if exist(fname_output, 'file')
        disp('Loading existing output data...');
        load(fname_output);
    end

    if strcmp(type_data,'Sensor')
        load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_sensor_%s_spect.mat',modalities)), ...
            'A_for_Cov', 'features', 'group_num', 'mri_num');
    else
        if ismember(type_data, {'LCMV','eLORETA'})
            load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_DAiSS_%s_spect.mat',modalities)), ...
                'A_for_Cov', 'features', 'group_num', 'mri_num', 'type_invsol');
        else
            load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_%s_spect.mat',modalities)), ...
                'A_for_Cov', 'features', 'group_num', 'mri_num', 'type_invsol');
        end
    end

    if strcmp(type_data,'Sensor')
        X = features;
    else
        X = features(:,:,strcmp(type_invsol,type_data));
    end

    if datcorrection(i)
        X = X - A_for_Cov*pinv(A_for_Cov)*X; % Regress out confounds
    end
    tbl = array2table([X group_num], 'VariableNames', [dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames {'Group'}]);

    clear X features A_for_Cov group_num mri_num

    %% Run classification methods
%     disp('Evaluating RusBoost model ...');
%     tic;
%     [cvStats_RusBoost, honStats_RusBoost, colnames] = ...
%         class_learn_app_auto(@train_RussBoost_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
%     toc_RusBoost = toc;
%     save(fname_output);

    disp('Evaluating SubspDiscEnsemble models ...');
    tic;
    [cvStats_SubspDiscEnsemble, honStats_SubspDiscEnsemble, colnames] = ...
        class_learn_app_auto(@train_SubspDiscEnsemble, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_SubspDiscEnsemble = toc;
    save(fname_output);

    disp('Evaluating GaussNaiveBayes models ...');
    tic;
    [cvStats_GaussNaiveBayes, honStats_GaussNaiveBayes] = ...
        class_learn_app_auto(@train_GaussNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_GaussNaiveBayes = toc;
    save(fname_output);

    disp('Evaluating KernelNaiveBayes models ...');
    tic;
    [cvStats_KernelNaiveBayes, honStats_KernelNaiveBayes] = ...
        class_learn_app_auto(@train_KernelNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_KernelNaiveBayes = toc;
    save(fname_output);

    disp('Evaluating WideNeuralNet models ...');
    tic;
    [cvStats_WideNeuralNet, honStats_WideNeuralNet] = ...
        class_learn_app_auto(@train_WideNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_WideNeuralNet = toc;
    save(fname_output);

    disp('Evaluating BilayeredNeuralNet models ...');
    tic;
    [cvStats_BilayeredNeuralNet, honStats_BilayeredNeuralNet] = ...
        class_learn_app_auto(@train_BilayeredNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_BilayeredNeuralNet = toc;
    save(fname_output);

    disp('Evaluating KSVM models with Bayesian optimization ...');
    tic;
    [cvStats_KSVM_BayesianOptim, honStats_KSVM_BayesianOptim] = ...
        class_learn_app_auto(@train_KSVM_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
    toc_KSVM_BayesianOptim = toc;
    save(fname_output);
% 
% %     disp('Evaluating LogisticReg models with Bayesian optimization ...');
% %     tic;
% %     [cvStats_LogisticReg_BayesianOptim, honStats_LogisticReg_BayesianOptim] = ...
% %         class_learn_app_auto(@train_LogisticReg_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% %     toc_LogisticReg_BayesianOptim = toc;
% %     save(fname_output);
% % 
% %     disp('Evaluating ANN models with Bayesian optimization ...');
% %     tic;
% %     [cvStats_ANN_BayesianOptim, honStats_ANN_BayesianOptim] = ...
% %         class_learn_app_auto(@train_ANN_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm);
% %     toc_ANN_BayesianOptim = toc;
% %     save(fname_output);
end