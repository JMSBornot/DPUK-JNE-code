function run_features_classification_K10(modalities, type_data)

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

%%
datcorrection = [true false];

for i = 1:2
    if datcorrection(i)
        fname_output = sprintf('features_corrected_%s_%s.xlsx',modalities,type_data);
    else
        fname_output = sprintf('features_uncorrected_%s_%s.xlsx',modalities,type_data);
    end

    if strcmp(type_data,'Sensor')
        load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_sensor_%s_spect.mat',modalities)), ...
            'A_for_Cov', 'features', 'group_num');
    else
        if ismember(type_data, {'LCMV','eLORETA'})
            load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_DAiSS_%s_spect.mat',modalities)), ...
                'A_for_Cov', 'features', 'group_num', 'type_invsol');
        else
            load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_%s_spect.mat',modalities)), ...
                'A_for_Cov', 'features', 'group_num', 'type_invsol');
        end
    end

    if strcmp(type_data,'Sensor')
        X = features;
    else
        X = features(:,:,strcmp(type_invsol,type_data));
    end

    flag = isnan(X);
    if any(any(flag))
        warning('There are %d NaN entries.', nnz(flag));
        X(flag) = 0;
    end
    if datcorrection(i)
        X = X - A_for_Cov*pinv(A_for_Cov)*X; % Regress out confounds
    end
    tbl = array2table([group_num X], 'VariableNames', [{'Group'} dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames]);

    writetable(tbl, fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',fname_output), 'WriteMode', 'overwrite');
end