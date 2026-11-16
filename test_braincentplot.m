% test_brainplot
addpath('P:\alahmad\Matlab\Toolbox\spm12');

% if ~exist('spm_BIDS','file')
%     addpath('P:\alahmad\Matlab\Toolbox\spm12');
%     spm('Defaults','EEG');
% end

% type = 1; % spectral features with GLMNET
type = 2; % spectral features with correlation thresholded GLMNET

switch type
    case 1
        load('P:\alahmad\Matlab\Classification_Script\glmnet_uncorrected_MEG_LCMV_K10.mat')
        vec = x.Coefficients(2:end,:);
    case 2
        dname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Change\Linux';

        sensor = 'MEGPLANAR';
        inv = 'LCMV';
        th = '0.1';

        fname = sprintf('glmnet_uncorrected_%s_%s_K10_NMC20_alpha1_signcorr%s.mat', sensor, inv, th);

        load(fullfile(dname, fname));

        tmp = xlsread(fullfile('P:\alahmad\Matlab\BioFIND-data-paper', sprintf('features_uncorrected_%s_%s.xlsx',sensor,inv)));
        tmp = corrcoef(tmp);
        tmp = tmp(1,2:end);
        flag = (abs(tmp) >= 0.1);
        vec = zeros(3000, size(x.Coefficients,2));
        vec(flag,:) = x.Coefficients(2:end,:);
end

load('kmedoids_data.mat', 'Np', 'idx', 'C', 'dist');
surf = gifti('P:\alahmad\Matlab\Toolbox\spm12\canonical\cortex_8196.surf.gii');

freqband_labels = {'Delta', 'Theta', 'Alpha', 'Beta', {'Gamma' '(low)'}, {'Gamma' '(high)'}};

transp = 0.9; % transparancy value between 0 - 1
fcbar = true; % true if want to see colorbar
hlink = braincentplot(surf, C, vec, 2, freqband_labels, transp, fcbar);