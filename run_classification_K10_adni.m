function [tbl, preds] = run_classification_K10_adni(fcent, fnorm, typenorm)
% [tbl, preds] = run_classification_K10_adni(true, true);
% [tbl, preds] = run_classification_K10_adni([], [], 'residuals');
% [tbl, preds] = run_classification_K10_adni([], [], 'zscores');

% fcent = true;
% fnorm = true;
% 
% typenorm = 'residuals';
% % typenorm = 'zscores';

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

%%
ClassNames = {1 2};     % This is a binomial classification task: labels of the two classes (numeric, categorical or string)
IDC = 2;                % id of critical class
K = 10;                 % Number of folds in K fold cross-validation
NMC = 100;              % Number of Monte Carlo iteration (to get stable results as cross-validation creates random partitions)
NiterBayesOptim = 100;  % Number of Bayesian optimization iterations (used by classifiers that need to optimize hyperparameters)

fselname = 'Relieff';   % algorithm to select the features
% fselname = 'kruskalwallis';

statslabel = 'aparcaseg';

dirname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Freesurfer\Classification Script';
tbl = readtable(fullfile(dirname, sprintf('Combine2_%s_volume_LR.xlsx',statslabel)));
ignoreVars = {'lh_aparc_volume' 'Site' 'MMSE' 'Education' ...
    'x5th_Ventricle' 'Left_WM_hypointensities' 'Right_WM_hypointensities' 'non_WM_hypointensities' ...
    'Left_non_WM_hypointensities' 'Right_non_WM_hypointensities' 'MaskVol' 'BrainSegVol_to_eTIV' ...
    'MaskVol_to_eTIV' 'lhSurfaceHoles' 'rhSurfaceHoles' 'SurfaceHoles' 'BrainSegVolNotVent_1'};
% tbl = tbl(:,setdiff(tbl.Properties.VariableNames,ignoreVars));
tbl = removevars(tbl,ignoreVars);

tbl = renamevars(tbl, ["Sex","EstimatedTotalIntraCranialVol"], ["Gender","TIV"]);

% Remove columns with NaN entries
flag = any(ismissing(tbl));
tbl(:,flag) = [];

% remove outliers according to TIV
flag = ~isoutlier(tbl.TIV);
tbl = tbl(flag,:);

preds = tbl.Properties.VariableNames;

%% Run classification methods
if exist('typenorm','var') && ~isempty(typenorm)
    if ~ismember(typenorm,{'residuals', 'zscores'})
        error('The alternative data harmonization procedures are either ''residuals'' or ''zscores''.');
    end
    fname_output = sprintf('results_%s_%s.mat', statslabel, typenorm);
else
    typenorm = [];
    fname_output = sprintf('results_%s_fcent%d_fnorm%d.mat', statslabel, fcent, fnorm);
end

disp('Evaluating SubspDiscEnsemble models ...');
tic;
[cvStats_SubspDiscEnsemble, honStats_SubspDiscEnsemble, colnames] = ...
    class_learn_app_auto(@train_SubspDiscEnsemble, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_SubspDiscEnsemble = toc;
save(fname_output);

disp('Evaluating GaussNaiveBayes models ...');
tic;
[cvStats_GaussNaiveBayes, honStats_GaussNaiveBayes] = ...
    class_learn_app_auto(@train_GaussNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_GaussNaiveBayes = toc;
save(fname_output);

disp('Evaluating KernelNaiveBayes models ...');
tic;
[cvStats_KernelNaiveBayes, honStats_KernelNaiveBayes] = ...
    class_learn_app_auto(@train_KernelNaiveBayes, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_KernelNaiveBayes = toc;
save(fname_output);

disp('Evaluating WideNeuralNet models ...');
tic;
[cvStats_WideNeuralNet, honStats_WideNeuralNet] = ...
    class_learn_app_auto(@train_WideNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_WideNeuralNet = toc;
save(fname_output);

disp('Evaluating BilayeredNeuralNet models ...');
tic;
[cvStats_BilayeredNeuralNet, honStats_BilayeredNeuralNet] = ...
    class_learn_app_auto(@train_BilayeredNeuralNet, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_BilayeredNeuralNet = toc;
save(fname_output);

disp('Evaluating KSVM models with Bayesian optimization ...');
tic;
[cvStats_KSVM_BayesianOptim, honStats_KSVM_BayesianOptim] = ...
    class_learn_app_auto(@train_KSVM_BayesianOptim, fselname, tbl, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_KSVM_BayesianOptim = toc;
save(fname_output);