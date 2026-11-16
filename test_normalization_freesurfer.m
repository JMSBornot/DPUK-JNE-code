% test_normalization_freesurfer
GroupLabel = {'HC', 'MCI'};
GenderLabel = {'M', 'F'};

dname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Freesurfer\Combine LR';

% dname = 'C:\WORK\Tools\Cabecera\Alwani PhD\Data\excelfreesurfer';
% dname = 'C:\Users\borno\Downloads\archer\EMCIADNI';

% fname = 'aparc_area_unit_mm2.xlsx';
% [ndata, text, all] = xlsread(fullfile(dname,fname), 1, 'A1:BX145', 'basic');

% fname = 'aparc_Volume_unit_mm3.xlsx';
% [ndata, text, all] = xlsread(fullfile(dname,fname), '', '', 'basic');

% fname = 'Normalized_VBM Freesurfer_aseg_stats.xlsx';
% [ndata, text, all] = xlsread(fullfile(dname,fname), 1, 'A1:DS122', 'basic');

% fname = 'TotalLRVolume_unit_mm3.xlsx';
% [ndata, text, all] = xlsread(fullfile(dname,fname), 1, '', 'basic');

% fname = 'VBMBrainVolume.xlsx';
% [ndata, text, all] = xlsread(fullfile(dname,fname), 1, '', 'basic');

% fname = 'OasisRev_aparc_volume_LR_AL_LI.xlsx';
% fname = 'OasisRev_aseg_stats_AI_LI.xlsx';
% fname = 'OASIS_VBMonly.xlsx';

% fname = 'merged_EMCIADNI_aseg_stats.xlsx'
% fname = 'merged_EMCIADNI_aparc_area_lh.xlsx'
% fname = 'merged_EMCIADNI_aparc_area_rh.xlsx'
% fname = 'merged_EMCIADNI_aparc_meancurv_lh.xlsx'
% fname = 'merged_EMCIADNI_aparc_meancurv_rh.xlsx'
% fname = 'merged_EMCIADNI_aparc_volume_lh.xlsx'
% fname = 'merged_EMCIADNI_aparc_volume_rh.xlsx'
% fname = 'merged_EMCIADNI_aparc_thickness_lh.xlsx'
% fname = 'merged_EMCIADNI_aparc_thickness_rh.xlsx'
% fname = 'merged_EMCIADNI_aparc_thicknessstd_lh.xlsx'
% fname = 'merged_EMCIADNI_aparc_thicknessstd_rh.xlsx'

% fname = 'EMCI_uncorrected_brain volume.xlsx';

% fname = 'EMCI_uncorrected_TotalLRbrain_volume.xlsx';

fname = 'Combine_aparcaseg_volume_LR.xlsx';

[ndata, text, all] = xlsread(fullfile(dname,fname), 1, '', 'basic');

varnames = strip(all(1,:));

col_TIV = find(strcmp(varnames,'EstimatedTotalIntraCranialVol'));
% col_TIV = find(strcmp(varnames,'eTIV'));

% ignore_cols = {'lh.aparc.area' 'MMSE' 'PTEDUCAT'};
% col_TIV = find(strcmp(varnames,'eTIV'));

% ignore_cols = {'lh.aparc.volume' 'MMSE' 'PTEDUCAT'};
% col_TIV = find(strcmp(varnames,'eTIV'));

% ignore_cols = {'Measure:volume' 'MMSE' 'PTEDUCAT'  'Cortical thickness (mm)'};
% col_TIV = find(strcmp(varnames,'MaskVol-to-eTIV'));
% % col_TIV = find(strcmp(varnames,'WholeBrain'));

% ignore_cols = {'lh.aparc.volume' 'MMSE' 'PTEDUCAT'};
ignore_cols = {'lh.aparc.volume' 'MMSE' 'Education' 'Site'};

% col_TIV = find(strcmp(varnames,'eTIV'));

% ignore_cols = {'Sub ID' 'MMSE' 'Education' 'Handedness', 'EstimatedTotalIntraCranialVol', 'observations'};
% ignore_cols = {'ID' 'DX_bl' 'DX' 'ICV' 'MMSE' 'AGE' 'PTGENDER' 'PTEDUCAT'};

% col_TIV = find(strcmp(varnames,'eTIV'));
% col_TIV = find(strcmp(varnames,'EstimatedTotalIntraCranialVol'));
% col_TIV = find(strcmp(varnames,'TIV (cm3)'));


%% Control variables
col_AGE = find(strcmpi(varnames,'AGE'));
Age = cell2mat(all(2:end,col_AGE));

col_Gender = find(strcmp(varnames,'Sex'));
% col_Gender = find(strcmp(varnames,'gender'));
% col_Gender = find(strcmp(varnames,'PTGENDER'));
% Gender = all(2:end, col_Gender);
% GenderCode = strrep(Gender, 'Female', '2');
% GenderCode = strrep(GenderCode, 'Male', '1');
% GenderCode = str2num(char(GenderCode)); %#ok<ST2NM>
GenderCode = cell2mat(all(2:end, col_Gender));

col_Group = find(strcmp(varnames,'Group'));
Group = cell2mat(all(2:end, col_Group));

% col_Group = find(strcmp(varnames,'DX_bl'));
% Group = all(2:end, col_Group);
% Group = strrep(Group, 'EMCI', '2');
% Group = strrep(Group, 'HC', '1');
% Group = str2num(char(Group)); %#ok<ST2NM>

TIV = cell2mat(all(2:end, col_TIV));

% remove outliers according to TIV
indok = find(~isoutlier(TIV));
Group = Group(indok);
Age = Age(indok);
GenderCode = GenderCode(indok);
TIV = TIV(indok);

%% Numerical columns (to be normalized)
icol_norm = setdiff(setdiff(1:length(varnames), find(ismember(varnames,ignore_cols))), ...
    [col_AGE col_Gender col_Group col_TIV]);
% read numerical data
Nrow = length(TIV);
Nvar = length(icol_norm);
meas = zeros(Nrow,Nvar);
flag = true(1,Nvar);
for i = 1:Nvar
    try
        meas(:,i) = cell2mat(all(indok+1, icol_norm(i)));
    catch
        flag(i) = false;
    end
end
icol_norm = icol_norm(flag);
meas = meas(:,flag);
Nvar = length(icol_norm);

% plot first four measures as illustration
grouping = {GenderLabel(GenderCode) GroupLabel(Group)};
figure;
for i = 1:4
    subplot(2,2,i);
    gscatter(TIV, meas(:,i), grouping, 'bbrr', '.x', 8, 'on', 'TIV', ...
        strrep(varnames{icol_norm(i)},'_','\_'));
    legend('Location','NorthEastOutside');
    set(gca, 'FontSize', 16);
end
figure;
for i = 1:4
    subplot(2,2,i);
    gscatter(Age, meas(:,i), grouping, 'bbrr', '.x', 8, 'on', 'Age', ...
        strrep(varnames{icol_norm(i)},'_','\_'));
    legend('Location','NorthEastOutside');
    set(gca, 'FontSize', 16);
end

% normalization
flag = (Group==1);
% Covall = zscore([Age GenderCode TIV]);
Covall = [Age GenderCode TIV];
meas_centered = zeros(Nrow,Nvar);
for i = 1:Nvar
    %mdl = fitlm(Covall(flag,:), meas(flag,i), 'quadratic');
    %mdl = fitlm(Covall(flag,:), meas(flag,i), 'linear');
    mdl = fitlm(Covall(flag,:), meas(flag,i), 'interactions');

    [fitted,confint] = predict(mdl, Covall, 'Prediction', 'observation');
    meas_centered(:,i) = meas(:,i) - fitted;
    std = (confint(:,2) - fitted)/1.96;
    meas(:,i) = meas_centered(:,i)./std;
end


% % normalization
% meas_centered = zeros(Nrow,Nvar);
% ymean = zeros(Nrow,1);
% yci = zeros(Nrow,2);
% xy = [Age TIV];
% for i = 1:Nvar
%     y = meas(:,i);
%     if any(isnan(y)), continue; end,
%     
%     flag = (Group == 1) & (GenderCode == 2);
%     func_female = fit(xy(flag,:), y(flag), 'poly11');
%     flag = (Group == 1) & (GenderCode == 1);
%     func_male = fit(xy(flag,:), y(flag), 'poly11');
%     
%     flag = (GenderCode == 2);
%     [yci(flag,:),ymean(flag)] = predint(func_female, xy(flag,:), 0.95, 'observation', 'off');
%     flag = (GenderCode == 1);
%     [yci(flag,:),ymean(flag)] = predint(func_male, xy(flag,:), 0.95, 'observation', 'off');
%     ystd = (yci(:,2)-ymean)/1.96;
%     
%     meas_centered(:,i) = y - ymean;
%     meas(:,i) = meas_centered(:,i)./ystd;
% end

% plot first four measures after normalization as illustration
figure;
for i = 1:4
    subplot(2,2,i);
    gscatter(TIV, meas(:,i), grouping, 'bbrr', '.x', 8, 'on', 'TIV', ...
        strrep(varnames{icol_norm(i)},'_','\_'));
    legend('Location','NorthEastOutside');
    set(gca, 'FontSize', 16);
end
figure;
for i = 1:4
    subplot(2,2,i);
    gscatter(Age, meas(:,i), grouping, 'bbrr', '.x', 8, 'on', 'Age', ...
        strrep(varnames{icol_norm(i)},'_','\_'));
    legend('Location','NorthEastOutside');
    set(gca, 'FontSize', 16);
end

%% Save Excel table with centered data
celltbl = all([1; indok+1],:);
% replace the values for the normalized variables
for i = 1:Nvar
    celltbl(2:end,icol_norm(i)) = num2cell(meas_centered(:,i));
end
% save excell data
writecell(celltbl, fullfile(dname,sprintf('%s_%s',fname(1:end-5),'centered.xlsx')));

%% Save Excel table with normalized data
celltbl = all([1; indok+1],:);
% replace the values for the normalized variables
for i = 1:Nvar
    celltbl(2:end,icol_norm(i)) = num2cell(meas(:,i));
end
% save excell data
writecell(celltbl, fullfile(dname,sprintf('%s_%s',fname(1:end-5),'zscore.xlsx')));