function [tbl, tblMEG] = run_features_classification_combined(modalities, type_data)

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
dirname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Freesurfer\Classification Script';
tbl = readtable(fullfile(dirname, 'Combine_aparcaseg_proc.xlsx'));

load('participant_records.mat', 'participants');
codeMRI = char(tbl.lh_aparc_volume);
codeMRI = codeMRI(:,1:11);
codeMEG = char(participants.participant_id);
[flag,indMEGsel] = ismember(codeMRI, codeMEG, 'rows');
assert(all(flag), 'All MRI codes have to be contained in the dataset');

%% Load MEG features
if strcmp(type_data,'Sensor')
    load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_sensor_%s_spect.mat',modalities)), 'features', 'group_num');
else
    if ismember(type_data, {'LCMV','eLORETA'})
        load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_DAiSS_%s_spect.mat',modalities)), ...
            'features', 'group_num', 'type_invsol');
    else
        load(fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',sprintf('features_gamma_source_%s_spect.mat',modalities)), ...
            'features', 'group_num', 'type_invsol');
    end
end

if strcmp(type_data,'Sensor')
    X = features;
else
    X = features(:,:,strcmp(type_invsol,type_data));
end
X(isnan(X)) = 0; % only a few entries for subject 201 for MSP solution
tblMEG = array2table([group_num X], 'VariableNames', [{'Group'} dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames]);

% Selected MEG entries corresponding to MRI
tblMEG = tblMEG(indMEGsel,:);
fname_output = sprintf('features_uncorrected4comb_%s_%s.xlsx',modalities,type_data) % file name for unorrected MEG's derived data aligned with MRI extracted features for combined analysis
writetable(tblMEG, fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',fname_output), 'WriteMode', 'overwrite');