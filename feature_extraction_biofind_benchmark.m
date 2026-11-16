% feature_extraction_biofind_benchmark

% STEP 3: Feature extraction

% Prepared for Alwani Liyana's PhD project

% modalities = 'All';
modalities = 'MEG';
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
Nrun   = 100; % Number of runs to repeat cross-validation

%% Relative power in source space %%
% type_invsol = {'COH', 'MSP', 'EBB'};
type_invsol = {'eLORETA', 'LCMV'};

Nfeat = 6*500; % (delta, theta, alpha, beta, low and high gamma) relative power features x number of dipoles
features = zeros(nsub, Nfeat, length(type_invsol));

for sub = 1:nsub
    
    for indsol = 1:length(type_invsol)

        infile = fullfile(processed_pth,subdir{sub},sprintf('mesh_source_activity_%s_%s',modalities,type_invsol{indsol}))
        load(infile,'D');
        g = D.data(:,:,:);
        [Nd,NFFT,NE] = size(g);
        Nf = floor(NFFT/2) + 1;

        % some inverse solution values are NaN
        flag= any(any(isnan(g),3),2);
        g(flag,:,:) = 0;
        
        % Estimation of power spectral density
%         p = zeros(NE, Nf, Nd);
%         for e = 1:NE
%             [p(e,:,:),fP] = periodogram(g(:,:,e)',[],NFFT,D.Fsample);
%         end
%         p = squeeze(mean(p,1)); p=p';
%         fP = fP(fP<=50);
%         p = p(:,1:length(fP));

        PX = sqrt(mean(abs(fft(g.*hanning(NFFT)',NFFT,2)/NFFT).^2,3));
        freq = D.Fsample*(0:floor(NFFT/2))/NFFT;
        freq = freq(freq<=freq_cutoff);
        PX = PX(:,1:length(freq));
        fP = freq;
        p = PX;

        locDelta = (fP>=2.0 & fP<=4);
        locTheta = (fP>4 & fP<=8);
        locAlpha = (fP>8 & fP<=12);
        locBeta  = (fP>12 & fP<=30);
        locGammaLow = (fP>30 & fP<=48);
        locGammaHigh = (fP>=52 & fP<=86);
        locALL = (fP>=1.0 & fP<=freq_cutoff);

        totalp  = sum(p(:,locALL),2);
        deltaRp = sum((p(:,locDelta)./totalp),2);
        thetaRp = sum((p(:,locTheta)./totalp),2);
        alphaRp = sum((p(:,locAlpha)./totalp),2);
        betaRp = sum((p(:,locBeta)./totalp),2);
        gammaLowRp = sum((p(:,locGammaLow)./totalp),2);
        gammaHighRp = sum((p(:,locGammaHigh)./totalp),2);

        features(sub,:,indsol) = [deltaRp; thetaRp; alphaRp; betaRp; gammaLowRp; gammaHighRp];
    end
end

% save(sprintf('features_gamma_source_%s_spect.mat',modalities), ...
%     'features', 'group_num', 'mri_num', 'A_for_Cov', 'type_invsol');
save(sprintf('features_gamma_source_DAiSS_%s_spect.mat',modalities), ...
    'features', 'group_num', 'mri_num', 'A_for_Cov', 'type_invsol');

% Machine Learning
for indsol = 1:length(type_invsol)
    M   = features(:,:,indsol);
    aM = M - A_for_Cov*pinv(A_for_Cov)*M; % Regress out confounds
    A = [aM group_num];
    A = A(mri_num==1,:); % Remove subjects without T1 MRI
    flag = any(isnan(A));

    rng('default') % For reproducibility
    accuracy = repeated_CV(A(:,~flag),kFolds,Nrun);

    fprintf('\n===== %s =====\n', type_invsol{indsol});
    fprintf('Mean Acc = %.2f\n', mean(accuracy));
    fprintf('Std Acc = %.2f\n\n', std(accuracy));
end

keyboard

%% Relative power in sensor space %%
if strcmp(modalities,'All')
    Nfeat = 306;
elseif strcmp(modalities,'MEG')
    Nfeat = 102;
elseif strcmp(modalities,'MEGPLANAR')
    Nfeat = 204;
else
    Nfeat = -1;
end
features = zeros(nsub, 6*Nfeat);

for sub=1:length(subs)    
    infile = fullfile(processed_pth,subdir{sub},'redfspmeeg')

    D = spm_eeg_load(infile);
    D = D.montage('switch',0); % Data must be in sensor montage
    
    % Estimation of power spectral density
    g = D(indchantype(D,modalities),:,:);
    [Nch,NFFT,NE] = size(g);
    Nf = floor(NFFT/2) + 1;
    PX = sqrt(mean(abs(fft(g.*hanning(NFFT)',NFFT,2)/NFFT).^2,3));
    freq = D.fsample*(0:floor(NFFT/2))/NFFT;
    freq = freq(freq<=freq_cutoff);
    PX = PX(:,1:length(freq));
    fP = freq;
    p = PX;

    locDelta = (fP>=2.0 & fP<=4);
    locTheta = (fP>4 & fP<=8);
    locAlpha = (fP>8 & fP<=12);
    locBeta = (fP>12 & fP<=30);
    locGammaLow = (fP>30 & fP<=48);
    locGammaHigh = (fP>=52 & fP<=86);
    locALL = (fP>=1.0 & fP<=freq_cutoff);

    totalp  = sum(p(:,locALL),2);
    deltaRp = sum((p(:,locDelta)./totalp),2);
    thetaRp = sum((p(:,locTheta)./totalp),2);
    alphaRp = sum((p(:,locAlpha)./totalp),2);
    betaRp  = sum((p(:,locBeta)./totalp),2);
    gammaLowRp  = sum((p(:,locGammaLow)./totalp),2);
    gammaHighRp  = sum((p(:,locGammaHigh)./totalp),2);

    features(sub,:) = [deltaRp; thetaRp; alphaRp; betaRp; gammaLowRp; gammaHighRp];    
end

save(sprintf('features_gamma_sensor_%s_spect.mat',modalities), ...
    'features', 'group_num', 'mri_num', 'A_for_Cov');

% Machine Learning
M   = features;
aM = M - A_for_Cov * pinv(A_for_Cov) * M; % Regress out confounds
A = [aM group_num]; % For all subjects
rng('default') % For reproducibility
accuracy = repeated_CV(A,kFolds,Nrun);

fprintf('\n===== %s =====\n', 'Sensor spectral features');
fprintf('Mean Acc = %.2f\n', mean(accuracy));
fprintf('Std Acc = %.2f\n\n', std(accuracy));

keyboard

%% Connectivity measure: Amplitude Envelope Correlation %%

features  = [];
freqbands = {[8 13],[13 30]};

for ii = 1:length(freqbands)
    f=[];
    parfor sub = 1:length(subs)
        
        g = []; y = []; y0 = []; y1 = []; cm = [];
        infile = fullfile(processed_pth,subdir{sub},'beffdspmeeg');
        D = spm_eeg_load(infile);
        D = D.montage('switch',3); % Data must be in ROI montage
        
        % Remove bad badtrials
        g = D(:,:,:);
        g(:,:,D.badtrials)=[];
        
        % Remove source leakage using sysmetric Orthogonalisation
        y = reshape(g,D.nchannels,D.nsamples*size(g,3));  % generalise to Nsource,Ntime*Ntrials(good ones)
        y0 = ROInets.remove_source_leakage(y,'symmetric');
        
        % Filter to desired freq band
        y1 = ft_preproc_bandpassfilter(y0, D.fsample, freqbands{ii}, 4, 'but');
        y = reshape(y1,D.nchannels,D.nsamples,size(g,3));
        
        % Extract envelops
        Hen_lc_sep = [];
        for t=1:size(y,3)
            Hen_lc_sep(:,:,t) = hilbenv(squeeze(y(:,:,t)),1:D.nsamples,1,1);
        end
        
        Hen_lc_sep = reshape(Hen_lc_sep,D.nchannels,D.nsamples*size(g,3));
        
        % Calculate correlation
        cm = corr(resample(Hen_lc_sep',1,D.fsample));
        f(sub,:) = (cm(find(triu(cm,1))))';
        
    end
    features = [features f];
end
% Machine Learning
M   = features;
aM = M - A_for_Cov*pinv(A_for_Cov)*M; % Regress out confounds
A = [aM group_num];
A = A(mri_num==1,:); % Remove subjects without T1 MRI
rng(1) % For reproducibility
accuracy = repeated_CV(A,kFolds,Nrun);

mean(accuracy)
std(accuracy)
