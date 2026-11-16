function feature_extraction_COH(modalities, indsol)
% feature_extraction_COH

% STEP 3: Feature extraction

% Prepared for Alwani Liyana's PhD project

% modalities = 'All';
% modalities = 'MEG';
% modalities = 'MEGPLANAR';

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
addpath('P:\alahmad\Matlab\Toolbox\spm12');
% spm('Defaults','EEG');

addpath('P:\alahmad\Matlab\Toolbox\fieldtrip-20230125');
ft_defaults;

% BIDS and Processed directories
bwd = 'S:\BioFIND - BioFIND\BioFIND';
bidspth = fullfile(bwd,'MCIControls'); %BIDS Path

% addpath('P:\alahmad\Matlab\Toolbox\oslwin\spm12\src'); % adding folder which contains compiled mex: spm_jsonread

BIDS   = spm_BIDS(bidspth); % (If it does not work with OSL's SPM, so copy
% last version of spm_BIDS from data /biofind/data/codes/BioFIND-data-paper)
subs   = spm_BIDS(BIDS,'subjects', 'task', 'Rest');
nsub   = numel(subs);
subdir = cellfun(@(s) ['sub-' s], subs, 'UniformOutput',false);

processed_pth = 'P:\alahmad\Matlab\BioFIND-data-paper\Processed';

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

%% Connectivity measure: Amplitude Envelope Correlation %%
% indsol = 1;
% indsol = 2;
% indsol = 3;

% type_invsol = {'COH', 'MSP', 'EBB'};
type_invsol = {'eLORETA', 'LCMV'};

Nd = 500; % Number of dipoles
indsel = find(tril(ones(Nd),-1));
Nfeat = Nd*(Nd-1)/2;
freqbands = {[1.5 4.0], [4.0 8.0], [8.0 12.0], [12.0 30.0], [30.0 48.0], [52.0 86.0]};
features_coh = zeros(nsub, Nfeat, length(freqbands));
features_icoh = zeros(nsub, Nfeat, length(freqbands));
features_wpli = zeros(nsub, Nfeat, length(freqbands));

% configuration for FFT calculation for COH and iCOH
cfg_freq = [];
cfg_freq.method = 'mtmfft';
cfg_freq.taper = 'dpss';
cfg_freq.output = 'fourier';
cfg_freq.tapsmofrq = 5;

% configuration for FFT calculation for wpli debiased
cfg_wpli = [];
cfg_wpli.method = 'mtmfft';
cfg_wpli.taper = 'dpss';
cfg_wpli.tapsmofrq = 5;
cfg_wpli.output = 'powandcsd';
cfg_wpli.keeptrials = 'yes';

% configuration for COH and iCOH calculation
cfg_conn = [];
cfg_conn.method = 'coh';

% configuration for wpli calculation
cfg2_conn = [];
cfg2_conn.method = 'wpli_debiased';

% Main
for sub = 1:length(subs)
    infile = fullfile(processed_pth,subdir{sub},sprintf('mesh_source_activity_%s_%s',modalities,type_invsol{indsol})) %#ok<NOPRT>
    load(infile,'D');
    [Nc,Ns,Ne] = size(D.data);
    assert(Nc==Nd, 'Something is wrong!');

    data = [];
    data.trial = cell(1,Ne);
    data.time = cell(1,Ne);
    data.fsample = D.Fsample;
    data.label = cellstr(reshape(sprintf('dip%03d',1:Nd), 6, [])');
    data.time{1} = (0:Ns-1)/data.fsample;
    for i = 2:Ne
        data.time{i} = data.time{1};
    end
    for i = 1:Ne
        data.trial{i} = single(D.data(:,:,i));
    end

    clear D;

    for i = 1:length(freqbands)
        cfg_freq.foilim = freqbands{i};
        cfg_wpli.foilim = freqbands{i};

        % calculate the fourier coefficients (non-parametric derivation of power)
        freq = ft_freqanalysis(cfg_freq, data);

        % coherence calculation
        cfg_conn.complex = 'abs';
        coh = ft_connectivityanalysis(cfg_conn, freq);

        % imaginary part of coherency calculation
        cfg_conn.complex = 'absimag';
        icoh = ft_connectivityanalysis(cfg_conn, freq);

        % wpli_debiased
        freq = ft_freqanalysis(cfg_wpli, data);

        wpli = ft_connectivityanalysis(cfg2_conn, freq);
        wpli.wpli_debiasedspctrm(isnan(wpli.wpli_debiasedspctrm)) = 0;
        wpli.wpli_debiasedspctrm(wpli.wpli_debiasedspctrm<0) = 0;

        % Features
        features = mean(coh.cohspctrm, 3);
        features_coh(sub,:,i) = features(indsel);

        features = mean(icoh.cohspctrm, 3);
        features_icoh(sub,:,i) = features(indsel);

        features = mean(wpli.wpli_debiasedspctrm, 2);
        features_wpli(sub,:,i) = features;
    end
end

% Save coh features
features = single(reshape(features_coh, [nsub Nfeat*length(freqbands)]));
save(sprintf('features_gamma_coh_%s_%s.mat',modalities,type_invsol{indsol}), ...
    'features', 'group_num', 'mri_num', 'A_for_Cov');

% Save icoh features
features = single(reshape(features_icoh, [nsub Nfeat*length(freqbands)]));
save(sprintf('features_gamma_icoh_%s_%s.mat',modalities,type_invsol{indsol}), ...
    'features', 'group_num', 'mri_num', 'A_for_Cov');

% Save wpli features
features = single(reshape(features_wpli, [nsub Nfeat*length(freqbands)]));
save(sprintf('features_gamma_wpli_%s_%s.mat',modalities,type_invsol{indsol}), ...
    'features', 'group_num', 'mri_num', 'A_for_Cov');