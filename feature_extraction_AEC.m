% feature_extraction_AEC

% STEP 3: Feature extraction

% Prepared for Alwani Liyana's PhD project

% modalities = 'All';
% modalities = 'MEG';
modalities = 'MEGPLANAR';

%% Features Extraction

% A multi-site, multi-participant magnetoencephalography resting-state dataset
% to study dementia: The BioFIND dataset
%
% This script calculates connectivity measure, and relative power
% for reproducing BioFIND data paper results.
% It requires ROI data (see "preproc_beamform_ROI.m" first)
%
% Note: Please make sure you are using the latest version of OSL and SPM
% within your OSL directory

% Henson R.N 2020, Vaghari D 2020

% Sanchez-Bornot J.M., 2024: adapted for different data structures
% containing the inverse solution for different methods.

%% Define Paths and variables

dir_osl = 'P:\alahmad\Matlab\Toolbox\oslwin';

addpath(fullfile(dir_osl,'osl-core'))
osl_startup
osl_check_installation
addpath(fullfile(dir_osl, 'spm12', 'src'));

% BIDS and Processed directories
bwd = 'S:\BioFIND - BioFIND\BioFIND';
bidspth = fullfile(bwd,'MCIControls'); %BIDS Path

% addpath('P:\alahmad\Matlab\Toolbox\oslwin\spm12\src'); % adding folder which contains compiled mex: spm_jsonread

BIDS   = spm_BIDS(bidspth);
subs   = spm_BIDS(BIDS,'subjects', 'task', 'Rest');
nsub   = numel(subs);
subdir = cellfun(@(s) ['sub-' s], subs, 'UniformOutput',false);
procpth = fullfile(bidspth,'derivatives','meg_derivatives'); % If want maxfiltered files

processed_pth = 'P:\alahmad\Matlab\BioFIND-data-paper\Processed';

freq_cutoff = 90;

%% Define Paths and variables

% Define Confounds and Covariate matrix
participants = spm_load('participants-imputed.tsv');
group_num    = grp2idx(participants.group);
site_num     = grp2idx(participants.site);
sex_num      = grp2idx(participants.sex);
mri_num      = grp2idx(participants.sImaging);

A_for_Cov = [site_num sex_num zscore([participants.age...
    participants.Move1 participants.Move2...
    participants.Recording_time]) ones(size(participants.age))];

% Cross-Validation setting
kFolds = 10; % Number of folds for cross-validation (inner and outer loops)
NMC   = 20; % Number of runs to repeat cross-validation

%% Connectivity measure: Amplitude Envelope Correlation %%
% indsol = 1;
% indsol = 2;
indsol = 3;

type_invsol = {'COH', 'MSP', 'EBB'};
% type_invsol = {'eLORETA', 'LCMV'};

Nd = 500; % Number of dipoles
indsel = find(tril(ones(Nd),-1));
Nfeat = Nd*(Nd-1)/2;
freqbands = {[1.5 4.0], [4.0 8.0], [8.0 12.0], [12.0 30.0], [30.0 48.0], [52.0 86.0]};
features = zeros(nsub, Nfeat, length(freqbands));

for sub = 1:length(subs)
    infile = fullfile(processed_pth,subdir{sub},sprintf('mesh_source_activity_%s_%s',modalities,type_invsol{indsol}))
    load(infile,'D');
    g = D.data(:,:,:);
    [Nc,Ns,Ne] = size(g);
    Hen_lc_sep = zeros(Nc,Ns,Ne);

    try
        for ii = 1:length(freqbands)
            % Remove source leakage using symmetric Orthogonalisation
            y = reshape(g, Nc, Ns*Ne);  % generalise to Nsource,Ntime*Ntrials(good ones)
            y0 = ROInets.remove_source_leakage(y,'symmetric');

            % Filter to desired freq band
            y1 = ft_preproc_bandpassfilter(y0, D.Fsample, freqbands{ii}, 4, 'but');
            y = reshape(y1, [Nc Ns Ne]);

            % Extract envelops
            for e = 1:Ne
                Hen_lc_sep(:,:,e) = hilbenv(y(:,:,e), 1:Ns, 1, 1);
            end

            tmp = reshape(Hen_lc_sep, [Nc Ns*Ne])';

            % Calculate correlation
            cm = corr(resample(tmp, 1, D.Fsample));
            features(sub,:,ii) = cm(indsel);
        end
    catch
        warning('Possibly the ROI time-course matrix is not full rank. Subject will be ignored.');
        continue;
    end
end
features = single(reshape(features, [nsub Nfeat*length(freqbands)]));

save(sprintf('features_gamma_conn_%s_%s.mat',modalities,type_invsol{indsol}), ...
    'features', 'group_num', 'mri_num', 'A_for_Cov');

%% Machine Learning
% K = 10;
% NMC = 20;
% 
% % features = features - A_for_Cov*pinv(A_for_Cov)*features; % Regress out confounds
% features = [features group_num];
% 
% features = single(features); % Force features into single precision due to RAM limitations in DPUK computers
% 
% features = features(mri_num==1,:); % Remove subjects without T1 MRI
% rng(1) % For reproducibility
% accuracy = repeated_CV_relieff(features, K, NMC);
% 
% mean(accuracy)
% std(accuracy)
% 
% % fname_output = sprintf('results_conn_uncorrected_ksvm_%s_%s_K%d.mat', 'MEGPLANAR', 'LCMV', K);
% % fname_output = sprintf('results_conn_uncorrected_ksvm_%s_%s_K%d.mat', 'MEG', 'LCMV', K);
% % fname_output = sprintf('results_conn_uncorrected_ksvm_%s_%s_K%d.mat', 'MEGPLANAR', 'eLORETA', K);
% fname_output = sprintf('results_conn_uncorrected_ksvm_%s_%s_K%d.mat', 'MEG', 'eLORETA', K);
% save(fname_output, 'accuracy');