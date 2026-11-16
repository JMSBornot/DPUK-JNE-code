% prepare_excell_Malab2Rstudio

statslabel = 'aparcaseg';

dirname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Freesurfer\Classification Script';
tbl = readtable(fullfile(dirname, sprintf('Combine2_%s_volume_LR.xlsx',statslabel)));
tbl = renamevars(tbl, "Sex", "Gender");
eTIV = tbl.EstimatedTotalIntraCranialVol;
ignoreVars = {'Site' 'MMSE' 'Education' ...
    'x5th_Ventricle' 'Left_WM_hypointensities' 'Right_WM_hypointensities' 'non_WM_hypointensities' ...
    'Left_non_WM_hypointensities' 'Right_non_WM_hypointensities' 'MaskVol' 'BrainSegVol_to_eTIV' ...
    'MaskVol_to_eTIV' 'lhSurfaceHoles' 'rhSurfaceHoles' 'SurfaceHoles' 'BrainSegVolNotVent_1', 'EstimatedTotalIntraCranialVol'};
tbl = removevars(tbl,ignoreVars);
tbl = addvars(tbl, eTIV, 'After', 'Age');

% Remove columns with NaN entries
flag = any(ismissing(tbl));
tbl(:,flag) = [];

% remove outliers according to TIV
flag = ~isoutlier(tbl.eTIV);
tbl = tbl(flag,:);

writetable(tbl, fullfile(dirname,sprintf('Combine_%s_proc.xlsx',statslabel)), 'WriteMode', 'overwrite');