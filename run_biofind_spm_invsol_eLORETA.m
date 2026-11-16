% run_biofind_spm_invsol_eLORETA

% Step 2: Source localization applied with different methods

% Prepared for Alwani Liyana's PhD project

% modalities = 'All';
modalities = 'MEG';
% modalities = 'MEGPLANAR';

% modalities = 'MEGMAG';
% % modalities = 'MEGPLANAR';

% BIDS and Processed directories
bwd = 'S:\BioFIND - BioFIND\BioFIND';
bidspth = fullfile(bwd,'MCIControls'); %BIDS Path

%% Define Paths and variables

if ~exist('spm_BIDS','file')
    addpath('P:\alahmad\Matlab\Toolbox\spm_github\spm_github');
    spm('Defaults','EEG');
    addpath('P:\alahmad\Matlab\Toolbox\spm_github\spm_github\toolbox\DAiSS');
end

% dir_osl = 'P:\alahmad\Matlab\Toolbox\oslwin';
% % dir_osl = 'P:\alahmad\Matlab\Toolbox\osl';
% % dir_osl = 'P:\alahmad\Matlab\Toolbox\osl2019';
% 
% addpath(fullfile(dir_osl,'osl-core'))
% osl_startup
% osl_check_installation
% addpath(fullfile(dir_osl, 'spm12', 'src'));

% BIDS and Processed directories
bwd = 'S:\BioFIND - BioFIND\BioFIND';
bidspth = fullfile(bwd,'MCIControls'); %BIDS Path

% addpath('P:\alahmad\Matlab\Toolbox\oslwin\spm12\src'); % adding folder which contains compiled mex: spm_jsonread

BIDS   = spm_BIDS(bidspth); % (If it does not work with OSL's SPM, so copy
% last version of spm_BIDS from data /biofind/data/codes/BioFIND-data-paper)
subs   = spm_BIDS(BIDS,'subjects', 'task', 'Rest');
nsub   = numel(subs);
subdir = cellfun(@(s) ['sub-' s], subs, 'UniformOutput',false);
procpth = fullfile(bidspth,'derivatives','meg_derivatives'); % If want maxfiltered files

processed_pth = 'P:\alahmad\Matlab\BioFIND-data-paper\Processed';

%% Define medoids
% surf = gifti('P:\alahmad\Matlab\Toolbox\spm_github\canonical\cortex_8196.surf.gii');
% Np = 500;
% tic;
% [idx, C] = kmedoids(surf.vertices, Np, 'Algorithm', 'small', 'OnlinePhase', 'on', 'Replicates', 10, 'Start', 'sample');
% toc
% dist = sqrt(squeeze(sum((C - reshape(C',[1 3 Np])).^2,2)));
% dist(eye(Np)~=0) = realmax;
% figure; histogram(min(dist,[],2),20);
% 
% figure;
% patch('faces',surf.faces,'vertices',surf.vertices,'FaceColor',0.9*ones(1,3),'EdgeColor','none','FaceAlpha',.5);
% lightangle(gca,-45,30); lighting gouraud, rotate3d on; axis image;
% hold on;
% scatter3(C(:,1),C(:,2),C(:,3),30,'r','filled');
% hold off
% 
% % save('kmedoids_data.mat', 'Np', 'idx', 'C', 'surf', 'dist');

load('kmedoids_data.mat', 'Np', 'idx', 'C', 'surf', 'dist');

%% Importing data into DAiSS (Menu SPM -> Tools -> DAiSS (beamforming) -> Prepare data)
addpath('P:\alahmad\Matlab\Toolbox\oslwin\spm12\toolbox\DAiSS');

matlabbatch = [];
ind = 1;
matlabbatch{ind}.spm.tools.beamforming.data.val = 1;
matlabbatch{ind}.spm.tools.beamforming.data.gradsource = 'inv';
matlabbatch{ind}.spm.tools.beamforming.data.space = 'MNI-aligned';
matlabbatch{ind}.spm.tools.beamforming.data.overwrite = 1;
% spm_jobman('run',matlabbatch);

%% Specifying a source space (Menu SPM -> Tools -> DAiSS (beamforming) -> Define sources)
% matlabbatch = [];
ind = 2;
matlabbatch{ind}.spm.tools.beamforming.sources.reduce_rank = [2 3];
matlabbatch{ind}.spm.tools.beamforming.sources.keep3d = 1;
matlabbatch{ind}.spm.tools.beamforming.sources.plugin.mesh.orient = 'original';
matlabbatch{ind}.spm.tools.beamforming.sources.plugin.mesh.fdownsample = 1;
matlabbatch{ind}.spm.tools.beamforming.sources.plugin.mesh.symmetric = 'no';
matlabbatch{ind}.spm.tools.beamforming.sources.plugin.mesh.flip = false;
matlabbatch{ind}.spm.tools.beamforming.sources.visualise = true;
% spm_jobman('run',matlabbatch);

%% Generating the covariance matrix (Menu SPM -> Tools -> DAiSS (beamforming) -> Covariance features)
% matlabbatch = [];
ind = 3;
matlabbatch{ind}.spm.tools.beamforming.features.whatconditions.all = 1;
matlabbatch{ind}.spm.tools.beamforming.features.woi = [-Inf Inf];
matlabbatch{ind}.spm.tools.beamforming.features.modality = {modalities};
matlabbatch{ind}.spm.tools.beamforming.features.fuse = 'no';
% matlabbatch{ind}.spm.tools.beamforming.features.plugin.cov.foi = [0 Inf];
matlabbatch{ind}.spm.tools.beamforming.features.plugin.cov.foi = [5 25];
% matlabbatch{ind}.spm.tools.beamforming.features.plugin.cov.taper = 'none';
matlabbatch{ind}.spm.tools.beamforming.features.plugin.cov.taper = 'hanning';

% % matlabbatch{ind}.spm.tools.beamforming.features.regularisation.manual.lambda = 5;
% matlabbatch{ind}.spm.tools.beamforming.features.regularisation.manual.lambda = 1;

matlabbatch{ind}.spm.tools.beamforming.features.regularisation.clifftrunc.zthresh = -1;
matlabbatch{ind}.spm.tools.beamforming.features.regularisation.clifftrunc.omit = 0;

matlabbatch{ind}.spm.tools.beamforming.features.bootstrap = false;
matlabbatch{ind}.spm.tools.beamforming.features.visualise = true;
% spm_jobman('run',matlabbatch);

%% Source inversion (Menu SPM -> Tools -> DAiSS (beamforming) -> Inverse solution)
% matlabbatch = [];
ind = 4;
% matlabbatch{ind}.spm.tools.beamforming.inverse.plugin.eloreta.regularisation = 0.05;
matlabbatch{ind}.spm.tools.beamforming.inverse.plugin.eloreta.regularisation = 1;
% spm_jobman('run',matlabbatch);

%% Set output to "montage" (Menu SPM -> Tools -> DAiSS (beamforming) -> Output)
% matlabbatch = [];
ind = 5;
matlabbatch{ind}.spm.tools.beamforming.output.plugin.montage.method = 'keep';
matlabbatch{ind}.spm.tools.beamforming.output.plugin.montage.vois = {};
% spm_jobman('run',matlabbatch);

%% Save in SPM's MEEG format (Menu SPM -> Tools -> DAiSS (beamforming) -> Write)
% matlabbatch = [];
ind = 6;
matlabbatch{ind}.spm.tools.beamforming.write.plugin.spmeeg.mode = 'write';
matlabbatch{ind}.spm.tools.beamforming.write.plugin.spmeeg.modality = modalities;
matlabbatch{ind}.spm.tools.beamforming.write.plugin.spmeeg.addchannels.none = 0;
matlabbatch{ind}.spm.tools.beamforming.write.plugin.spmeeg.prefix = 'eLOR_vol_';
% spm_jobman('run',matlabbatch);

%% Run ALL
[flag,inddip] = ismember(C, surf.vertices, 'rows');
E = [];
for i = 1:nsub
    disp(i)
    resdir = fullfile(processed_pth, subdir{i})
    matlabbatch{1}.spm.tools.beamforming.data.dir = {resdir};
    matlabbatch{1}.spm.tools.beamforming.data.D = {fullfile(resdir,'redfspmeeg.mat')};
    matlabbatch{2}.spm.tools.beamforming.sources.BF = {fullfile(resdir,'BF.mat')};
    matlabbatch{3}.spm.tools.beamforming.features.BF = {fullfile(resdir,'BF.mat')};
    matlabbatch{4}.spm.tools.beamforming.inverse.BF = {fullfile(resdir,'BF.mat')};
    matlabbatch{5}.spm.tools.beamforming.output.BF = {fullfile(resdir,'BF.mat')};
    matlabbatch{6}.spm.tools.beamforming.write.BF = {fullfile(resdir,'BF.mat')};
    spm_jobman('run',matlabbatch);

    % Extract source activity at medoid points
    D = spm_eeg_load(fullfile(resdir, 'eLOR_vol_redfspmeeg.mat'));
    E.Fsample = D.fsample;
    E.data = D(inddip,:,:);
    delete(fullfile(resdir,'BF.mat'));
    delete(D);
    D = E;
    fout = fullfile(resdir,sprintf('mesh_source_activity_%s_eLORETA.mat',modalities));
    save(fout, 'D');
end