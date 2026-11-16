function [tbl, tblMEG] = run_classification_K10_combined(modalities, type_data, typenorm)
% [tbl, preds] = run_classification_K10_combined(true, true);
% [tbl, preds] = run_classification_K10_combined('MEGPLANAR', 'Sensor', 'zscores');
% [tbl, preds] = run_classification_K10_combined('MEGMAG', 'Sensor', 'zscores');
% [tbl, preds] = run_classification_K10_combined('MEGMAG', 'COH', 'zscores');

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

%%
statslabel = 'aparcaseg';

dirname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Freesurfer\Classification Script';
tbl = readtable(fullfile(dirname, sprintf('Combine2_%s_volume_LR.xlsx',statslabel)));

load('participant_records.mat', 'participants');
codeMRI = char(tbl.lh_aparc_volume);
codeMRI = codeMRI(:,1:11);
codeMEG = char(participants.participant_id);
[flag,indMEGsel] = ismember(codeMRI, codeMEG, 'rows');
assert(all(flag), 'All MRI codes have to be contained in the dataset');

tbl = renamevars(tbl, ["Sex","EstimatedTotalIntraCranialVol"], ["Gender","TIV"]);

% remove outliers according to TIV
flag = ~isoutlier(tbl.TIV);
tbl = tbl(flag,:);
indMEGsel = indMEGsel(flag);

%% Load MEG features
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
X(isnan(X)) = 0; % only a few entries for subject 201 for MSP solution
tblMEG = array2table([X group_num], 'VariableNames', [dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames {'Group'}]);

%% Combine features and prepare output
assert(all(all([A_for_Cov(indMEGsel,1:2) group_num(indMEGsel)] == [3-tbl.Site tbl.Gender tbl.Group])), ...
    'The entries for MEG and MRI features must be compatible.')

ignoreVars = {'lh_aparc_volume' 'Site' 'MMSE' 'Education' ...
    'x5th_Ventricle' 'Left_WM_hypointensities' 'Right_WM_hypointensities' 'non_WM_hypointensities' ...
    'Left_non_WM_hypointensities' 'Right_non_WM_hypointensities' 'MaskVol' 'BrainSegVol_to_eTIV' ...
    'MaskVol_to_eTIV' 'lhSurfaceHoles' 'rhSurfaceHoles' 'SurfaceHoles' 'BrainSegVolNotVent_1'};
tbl = removevars(tbl,ignoreVars);

% Remove columns with NaN entries
flag = any(ismissing(tbl));
tbl(:,flag) = [];

% Selected MEG entries corresponding to MRI
tblMEG = tblMEG(indMEGsel,:);

clear X features A_for_Cov group_num mri_num

%% Run classification methods
fname_output = sprintf('results_combined_uncorrected_%s_%s_%s_K%d.mat',type_data,modalities,fselname,K);
if exist(fname_output, 'file')
    disp('Loading existing output data...');
    load(fname_output);
end

if exist('typenorm','var') && ~isempty(typenorm)
    if ~ismember(typenorm,{'residuals', 'zscores'})
        error('The alternative data harmonization procedures are either ''residuals'' or ''zscores''.');
    end
else
    typenorm = [];
end

disp('Evaluating SubspDiscEnsemble models ...');
tic;
[cvStats_SubspDiscEnsemble, honStats_SubspDiscEnsemble, colnames] = ...
    class_learn_comb_auto(@train_SubspDiscEnsemble, fselname, tbl, tblMEG, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_SubspDiscEnsemble = toc;
save(fname_output);

disp('Evaluating GaussNaiveBayes models ...');
tic;
[cvStats_GaussNaiveBayes, honStats_GaussNaiveBayes] = ...
    class_learn_comb_auto(@train_GaussNaiveBayes, fselname, tbl, tblMEG, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_GaussNaiveBayes = toc;
save(fname_output);

disp('Evaluating KernelNaiveBayes models ...');
tic;
[cvStats_KernelNaiveBayes, honStats_KernelNaiveBayes] = ...
    class_learn_comb_auto(@train_KernelNaiveBayes, fselname, tbl, tblMEG, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_KernelNaiveBayes = toc;
save(fname_output);

disp('Evaluating WideNeuralNet models ...');
tic;
[cvStats_WideNeuralNet, honStats_WideNeuralNet] = ...
    class_learn_comb_auto(@train_WideNeuralNet, fselname, tbl, tblMEG, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_WideNeuralNet = toc;
save(fname_output);

disp('Evaluating BilayeredNeuralNet models ...');
tic;
[cvStats_BilayeredNeuralNet, honStats_BilayeredNeuralNet] = ...
    class_learn_comb_auto(@train_BilayeredNeuralNet, fselname, tbl, tblMEG, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_BilayeredNeuralNet = toc;
save(fname_output);

disp('Evaluating KSVM models with Bayesian optimization ...');
tic;
[cvStats_KSVM_BayesianOptim, honStats_KSVM_BayesianOptim] = ...
    class_learn_comb_auto(@train_KSVM_BayesianOptim, fselname, tbl, tblMEG, ClassNames, IDC, K, NMC, NiterBayesOptim, fcent, fnorm, typenorm);
toc_KSVM_BayesianOptim = toc;
save(fname_output);