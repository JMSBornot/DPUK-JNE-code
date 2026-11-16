% run_biofind_spm_invsol

% Step 2: Source localization applied with different methods

% Prepared for Alwani Liyana's PhD project

% modalities = 'All';
modalities = 'MEG';
% modalities = 'MEGPLANAR';

% BIDS and Processed directories
bwd = 'S:\BioFIND - BioFIND\BioFIND';
bidspth = fullfile(bwd,'MCIControls'); %BIDS Path

%% Define Paths and variables

dir_osl = 'P:\alahmad\Matlab\Toolbox\oslwin';
% dir_osl = 'P:\alahmad\Matlab\Toolbox\osl';
% dir_osl = 'P:\alahmad\Matlab\Toolbox\osl2019';

addpath(fullfile(dir_osl,'osl-core'))
osl_startup
osl_check_installation
addpath(fullfile(dir_osl, 'spm12', 'src'));

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

type_invsol = {'COH', 'MSP', 'EBB'};

%% Source inversion
matlabbatch = [];

matlabbatch{1}.spm.meeg.source.invert.val = 1;
matlabbatch{1}.spm.meeg.source.invert.whatconditions.all = 1;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.woi = [-inf Inf];
% matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.foi = [1 48];
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.foi = [1 90];
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.hanning = 1;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.priors.priorsmask = {''};
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.priors.space = 1;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.restrict.locs = zeros(0, 3);
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.restrict.radius = 32;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.restrict.mask = {''};
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.modality = {'MEGMAG', 'MEGPLANAR'};
matlabbatch{1}.spm.meeg.source.invert.modality = {modalities};

%% Extract source activity at the mesh vertices
matlabbatch{2}.spm.meeg.source.extract.val = 1;
for i = 1:Np
    matlabbatch{2}.spm.meeg.source.extract.source(i).label = sprintf('medoid_%d',i);
    matlabbatch{2}.spm.meeg.source.extract.source(i).xyz = C(i,:);
end
matlabbatch{2}.spm.meeg.source.extract.rad = 5;
matlabbatch{2}.spm.meeg.source.extract.type = 'trials';

%% Run All
for ind = 1:nsub

% for ind = 251:nsub

% for ind = 165:250

% for ind = 166:166

% for ind = 165:165

    disp(ind);
    fname = fullfile(processed_pth,subdir{ind},'redfspmeeg.mat')
    matlabbatch{1}.spm.meeg.source.invert.D = {fname};
    matlabbatch{2}.spm.meeg.source.extract.D = {fname};

    for indsol = 1:length(type_invsol)
        matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.invtype = type_invsol{indsol};
        matlabbatch{2}.spm.meeg.source.extract.fname = sprintf('mesh_source_activity_%s_%s',modalities,type_invsol{indsol});

        spm_jobman('run',matlabbatch(1));
        spm_jobman('run',matlabbatch(2));
        drawnow;
    end
end