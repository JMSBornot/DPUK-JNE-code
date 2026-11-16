function run_features_connectivity(modalities, type_data)

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

Nfeat = 500;
Nfeat = Nfeat*(Nfeat-1)/2;

dvarnames = cellfun(@(x) sprintf('Delta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
tvarnames = cellfun(@(x) sprintf('Theta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
avarnames = cellfun(@(x) sprintf('Alpha_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
bvarnames = cellfun(@(x) sprintf('Beta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
gLvarnames = cellfun(@(x) sprintf('GammaL_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
gHvarnames = cellfun(@(x) sprintf('GammaH_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);

%%
fname_output = sprintf('features_connectivity_%s_%s.xlsx',modalities,type_data);
load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_conn_%s_%s.mat',modalities,type_data)), 'features', 'group_num');
X = features;

flag = isnan(X);
if any(any(flag))
    warning('There are %d NaN entries.', nnz(flag));
    X(flag) = 0;
end
tbl = array2table([group_num X], 'VariableNames', [{'Group'} dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames]);

writetable(tbl, fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',fname_output), 'WriteMode', 'overwrite');