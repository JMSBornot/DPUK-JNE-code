% run_spm_invsol

% STEP 2: Inverse solution for ALL, only MEGMAG, or only MEGPLANAR data

% Prepared for Alwani Liyana's PhD project

surf = gifti('P:\alahmad\Matlab\Toolbox\spm_github\canonical\cortex_8196.surf.gii');
Np = 500;
tic;
[idx, C] = kmedoids(surf.vertices, Np, 'Algorithm', 'small', 'OnlinePhase', 'on', 'Replicates', 100, 'Start', 'sample');
toc
dist = sqrt(squeeze(sum((C - reshape(C',[1 3 Np])).^2,2)));
dist(eye(Np)~=0) = realmax;
figure; histogram(min(dist,[],2),20);

fname = fullfile('P:\alahmad\Matlab\BioFIND-data-paper\Processed\sub-Sub0001', 'redfspmeeg.mat');
type_invsol = {'COH', 'MSP', 'EBB'};
indsol = 1;

%% Source inversion
matlabbatch = [];

matlabbatch{1}.spm.meeg.source.invert.D = {fname};
matlabbatch{1}.spm.meeg.source.invert.val = 1;
matlabbatch{1}.spm.meeg.source.invert.whatconditions.all = 1;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.invtype = type_invsol{indsol};
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.woi = [0 1000];
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.foi = [1 48];
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.hanning = 1;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.priors.priorsmask = {''};
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.priors.space = 1;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.restrict.locs = zeros(0, 3);
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.restrict.radius = 32;
matlabbatch{1}.spm.meeg.source.invert.isstandard.custom.restrict.mask = {''};
matlabbatch{1}.spm.meeg.source.invert.modality = {'All'};

%% Extract source activity at the mesh vertices
matlabbatch{2}.spm.meeg.source.extract.D = {fname};
matlabbatch{2}.spm.meeg.source.extract.val = 1;
for i = 1:Np
    matlabbatch{2}.spm.meeg.source.extract.source(i).label = sprintf('medoid_%d',i);
    matlabbatch{2}.spm.meeg.source.extract.source(i).xyz = C(i,:);
end
matlabbatch{2}.spm.meeg.source.extract.rad = 5;
matlabbatch{2}.spm.meeg.source.extract.type = 'trials';
matlabbatch{2}.spm.meeg.source.extract.fname = sprintf('mesh_source_activity_%s',type_invsol{indsol});

%% Run All
spm_jobman('run',matlabbatch);