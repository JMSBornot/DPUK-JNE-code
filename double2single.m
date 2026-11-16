function double2single

% pause(50*60);

% load('features_gamma_coh_MEG_eLORETA.mat')
% features = single(features);
% save('features_gamma_coh_MEG_eLORETA.mat')
% 
% load('features_gamma_icoh_MEG_eLORETA.mat')
% features = single(features);
% save('features_gamma_icoh_MEG_eLORETA.mat')
% 
% load('features_gamma_wpli_MEG_eLORETA.mat')
% features = single(features);
% save('features_gamma_wpli_MEG_eLORETA.mat')



load('features_gamma_coh_MEG_LCMV.mat')
features = single(features);
save('features_gamma_coh_MEG_LCMV.mat')

load('features_gamma_icoh_MEG_LCMV.mat')
features = single(features);
save('features_gamma_icoh_MEG_LCMV.mat')

load('features_gamma_wpli_MEG_LCMV.mat')
features = single(features);
save('features_gamma_wpli_MEG_LCMV.mat')