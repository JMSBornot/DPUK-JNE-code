function [tbl, tblMEG] = run_features_classification_allcombined(typedata)

if strcmp(typedata,'Sensor')
    Nfeat = 306;
else
    Nfeat = 1000;
end

dvarnames = cellfun(@(x) sprintf('Delta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
tvarnames = cellfun(@(x) sprintf('Theta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
avarnames = cellfun(@(x) sprintf('Alpha_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
bvarnames = cellfun(@(x) sprintf('Beta_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
gLvarnames = cellfun(@(x) sprintf('GammaL_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);
gHvarnames = cellfun(@(x) sprintf('GammaH_%d',x), num2cell(1:Nfeat), 'UniformOutput', false);

dirname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Freesurfer\Classification Script';
tbl = readtable(fullfile(dirname, 'Combine_aparcaseg_proc.xlsx'));

load('participant_records.mat', 'participants');
codeMRI = char(tbl.lh_aparc_volume);
codeMRI = codeMRI(:,1:11);
codeMEG = char(participants.participant_id);
[flag,indMEGsel] = ismember(codeMRI, codeMEG, 'rows');
assert(all(flag), 'All MRI codes have to be contained in the dataset');

%% Load MEG features
if strcmp(typedata,'Sensor')
    load('P:\alahmad\Matlab\BioFIND-data-paper\features_gamma_sensor_MEG_spect.mat', 'A_for_Cov', 'features', 'group_num');
    X = reshape(features, size(features,1), [], 6);
    load('P:\alahmad\Matlab\BioFIND-data-paper\features_gamma_sensor_MEGPLANAR_spect.mat', 'features');
    X = cat(2, X, reshape(features, size(features,1), [], 6));
else
    if ismember(typedata, {'LCMV','eLORETA'})
        load('P:\alahmad\Matlab\BioFIND-data-paper\features_gamma_source_DAiSS_MEG_spect.mat', 'A_for_Cov', 'features', 'group_num', 'type_invsol');
    else
        load('P:\alahmad\Matlab\BioFIND-data-paper\features_gamma_source_MEG_spect.mat', 'A_for_Cov', 'features', 'group_num', 'type_invsol');
    end
    X = reshape(features(:,:,strcmp(type_invsol,typedata)), size(features,1), [], 6);
    if ismember(typedata, {'LCMV','eLORETA'})
        load('P:\alahmad\Matlab\BioFIND-data-paper\features_gamma_source_DAiSS_MEGPLANAR_spect.mat', 'features');
    else
        load('P:\alahmad\Matlab\BioFIND-data-paper\features_gamma_source_MEGPLANAR_spect.mat', 'features');
    end
    X = cat(2, X, reshape(features(:,:,strcmp(type_invsol,typedata)), size(features,1), [], 6));
end
X(isnan(X)) = 0; % only a few entries are NaN for MSP solution: nnz(isnan(X))
tblMEG = array2table([group_num reshape(X,size(X,1),[])], 'VariableNames', [{'Group'} dvarnames tvarnames avarnames bvarnames gLvarnames gHvarnames]);

% Selected MEG entries corresponding to MRI
tblMEG = tblMEG(indMEGsel,:);
fname_output = sprintf('features_uncorrected4allcomb_%s.xlsx',typedata) % file name for unorrected MEG's derived data aligned with MRI extracted features for all combined analysis
writetable(tblMEG, fullfile('P:\alahmad\Matlab\BioFIND-data-paper\',fname_output), 'WriteMode', 'overwrite');