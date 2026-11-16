% test_barerrorplot

load('results_aparcaseg_auc_zscores_K10.mat');
% load('results_aparcaseg_auc_residuals_K10.mat');
% load('results_aparcaseg_auc_fcent1_fnorm1_K10.mat');

[~,varnames] = xlsread('S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Linux\Combine_aparcaseg_proc.xlsx'); %#ok<XLSRD> 
varnames = varnames(1,6:end);

zscore = barerrorplot(x.Coefficients(2:end,:), 2, 20, varnames);
