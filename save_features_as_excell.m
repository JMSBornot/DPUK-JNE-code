function save_features_as_excell(modalities, inv_method)

% % modalities = 'All';
% modalities = 'MEG';
% % modalities = 'MEGPLANAR';
% 
% % inv_method = 'COH';
% % inv_method = 'MSP';
% % inv_method = 'EBB';
% inv_method = 'Sensor';

if strcmp(inv_method,'Sensor')
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

if strcmp(inv_method,'Sensor')
    load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_sensor_%s_spect.mat',modalities)), ...
        'A_for_Cov', 'features', 'group_num', 'mri_num');
else
    load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_%s_spect.mat',modalities)), ...
        'A_for_Cov', 'features', 'group_num', 'mri_num', 'type_invsol');
end

if strcmp(inv_method,'Sensor')
    X = features;
else
    X = features(:,:,strcmp(type_invsol,inv_method));
end

colnames = [dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames ...
    {'Site' 'Gender' 'Age_zscore' 'Move1_zscore' 'Move2_zcore' 'Recording_time_zscore' 'intercept' 'mri_num' 'Group'}];
tbl = [colnames; num2cell([X A_for_Cov mri_num group_num])];
if strcmp(inv_method,'Sensor')
    writecell(tbl, sprintf('features_gamma_sensor_%s.xlsx',modalities));
else
    writecell(tbl, sprintf('features_gamma_%s_%s.xlsx',inv_method,modalities));
end