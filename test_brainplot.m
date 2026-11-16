% test_brainplot
addpath('C:\WORK\MATLAB\Toolboxes\spm12');
spm('Defaults','EEG');
surf = gifti('C:\WORK\MATLAB\Toolboxes\spm12\canonical\cortex_8196.surf.gii');

% dname = '.';
dname = 'C:\WORK\Tools\Cabecera\Alwani PhD\Matlab\Spectral_GLMNET_Results';

% type = 1; % spectral features with GLMNET
type = 2; % spectral features with correlation thresholded GLMNET

switch type
    case 1
        load('P:\alahmad\Matlab\Classification_Script\glmnet_uncorrected_MEG_LCMV_K10.mat')
        X = x.Coefficients(2:end,:);
    case 2
        sensor = 'MEGPLANAR';

        % inv = 'LCMV';
        inv = 'eLORETA';

        % th = '0.1';
        th = '0.05';

        fname_model = fullfile(dname, sprintf('glmnet_%s_%s_K10_alpha1_signcorr%s.mat', inv, sensor, th));
        load(fname_model);
        fname_corr = fullfile(dname, sprintf('correlation_spect_%s_%s.mat',inv, sensor));
        load(fname_corr);

        % flag = (abs(correlation) >= 0.1);
        flag = (abs(correlation) >= 0.05);

        X = zeros(length(correlation), size(x.Coefficients,2));
        X(flag,:) = x.Coefficients(2:end,:);
end

freqband_labels = {'Delta', 'Theta', 'Alpha', 'Beta', {'Gamma' '(low)'}, {'Gamma' '(high)'}};

% fcbar = true; % true if want to see colorbar
fcbar = false;
hlink = brainplot(surf, X, 2, freqband_labels, fcbar);