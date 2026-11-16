
% Step 1: Preprocession + Coregistration

% Prepared for Alwani Liyana's PhD project

%% Pre-Processing, Beamforming, ROI Extraction %%

% A multi-site, multi-participant magnetoencephalography resting-state
% dataset to study dementia: The BioFIND dataset
%
% This script contains preprocessing, co-registration, source-localisation
% and ROI extraction steps for reproducing BioFIND data paper results

% Note: Please make sure you are using the latest version of OSL and SPM
% within your OSL directory

% Henson R.N 2020, Vaghari D 2020

% Sanchez-Bornot J.M., 2024: modified to run OSL in Windows PC and altering
% some of the preprocessing steps (ignoring beamformer inverse solution
% calculation at the end).

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

%% Create Processed directory
% Please do all analysis in a separate directory from BIDS
% Here we call it "Processed"

if ~exist(processed_pth,'dir')

    mkdir('Processed');
    cd ('Processed')
    for s=1:nsub
        mkdir(sprintf('sub-Sub%04d',s))
    end
end

cd (processed_pth)

%% PreProcess- Part 1 (Convert, Downsample, Filter)
for sub = 1:length(subs)
    % Read event & json file to extract desirable length of MEG Recordings

    tmp = spm_jsonread(fullfile(procpth,subdir{sub},'ses-meg1','meg',[subdir{sub} '_ses-meg1_task-Rest_proc-sss_meg.json']));
    event_file = spm_load(fullfile(bidspth,subdir{sub},'ses-meg1','meg',[subdir{sub} '_ses-meg1_task-Rest_events.tsv']));
    onset = (event_file.onset*tmp.SamplingFrequency)+1;

    % offset = onset + event_file.duration*tmp.SamplingFrequency;
    offset = (onset + 120 *tmp.SamplingFrequency)-1; % we put 120 seconds due to min length of raw data

    % Converting

    S = [];
    S.outfile = fullfile(processed_pth,subdir{sub},'spmeeg');
    S.dataset = fullfile(procpth,subdir{sub},'ses-meg1','meg',[subdir{sub} '_ses-meg1_task-Rest_proc-sss_meg.fif']);
    S.mode = 'epoched';

%     S.channels = {'EOG', 'ECG', 'MEGMAG', 'MEGPLANAR'}; % EEG was removed
%     S.channels = {'EOG', 'ECG', 'MEGMAG'}; % EEG and MEGPLANAR were removed
    S.channels = {'MEGMAG' 'MEGPLANAR'}; % EEG and MEGPLANAR were removed

    S.checkboundary = 0;
    S.trl = [onset offset 0];
    try
        S.conditionlabels = event_file.stim_type;
    catch
        S.conditionlabels = event_file.trial_type;
    end
    D = spm_eeg_convert(S);

    % Set channel types and bad channels
    S = [];
    S.D    = D;
    S.task = 'bidschantype';
    S.save = 1;
    S.filename = fullfile(bidspth,subdir{sub},'ses-meg1','meg',[subdir{sub} '_ses-meg1_task-Rest_channels.tsv']);
    D = spm_eeg_prep(S);
    D = chantype(D,indchantype(D,'megmag'),'MEGMAG');
    D = chantype(D,indchantype(D,'megplanar'),'MEGPLANAR');
    D.save


    % Low pass filter using a higher-order matlab-based Butterworth filter
    % A higher order is needed to remove the very strong head position
    % indicator (HPI) signals contamination
    [b,a] = butter(9, 95/(D.fsample/2), 'low');
    x = filtfilt(b,a,D(:,:)');

    % High pass filter using matlab-based Butterworth filter
    [b,a] = butter(4, 1/(D.fsample/2), 'high');
    y = filtfilt(b,a,x);

    % Apply notch filter to remove the 50 Hz line noise
    [b,a] = butter(4, [49 51]/(D.fsample/2), 'stop');
    z = filtfilt(b,a,y);

    D(:,:) = z';
    clear x y z

    % Downsampling the data 
    S = [];
    S.D = D;
    S.method = 'resample';
    S.prefix = 'df';
    S.fsample_new = 250;
    D = spm_eeg_downsample(S);
    delete(S.D);

    % Epoching
    EpochLength = 1 * D.fsample; % in samples
    t = [1:EpochLength:(D.nsamples-EpochLength)]';
    nt = length(t);

    S = [];
    S.D = D;
    S.trl = [t t+EpochLength-1 zeros(nt,1)];
    S.conditionlabels = repmat({'EYES_CLOSED'},1,nt);
    S.prefix = 'e';
    S.bc = 0;
    D = spm_eeg_epochs(S);
    D.save;
    delete(S.D);

end


%% PreProcess- Part 2 - OSL Artifacts detection
for sub = 1:length(subs)
%     infile = fullfile(processed_pth,subdir{sub},'ffdspmeeg');
    infile = fullfile(processed_pth,subdir{sub},'edfspmeeg');
    D = spm_eeg_load(infile);

    % OSL artifact detection
    D = osl_detect_artefacts(D,'modalities',unique(D.chantype(D.indchantype('MEGANY'))),'badchannels',false);
    D.badtrials
    D.save;

    % Remove detected bad trials
    S = [];
    S.D = D;
    S.prefix = 'r';
    D = spm_eeg_remove_bad_trials(S);
    D.save;
%     delete(S.D);

end


%% RUN Standard COREGISTRATION using SPM

% Copy T1w files to processed directory;
for sub=1:length(subs)
    bidsT1 = fullfile(bidspth,subdir{sub},'ses-meg1','anat',[subdir{sub} '_ses-meg1_T1w.nii.gz']);
    T1file = fullfile(processed_pth,subdir{sub},[subdir{sub} '_ses-meg1_T1w.nii'])
    if exist(bidsT1,'file') & ~exist(T1file,'file')
        copyfile(bidsT1,[T1file '.gz']);
        gunzip([T1file '.gz'])
        delete([T1file '.gz'])
    end
end

%% Coregistration

UseHPs = 1; % Use headpoints

for sub=1:length(subs)
    
%     infile = fullfile(processed_pth,subdir{sub},'effdspmeeg');
    infile = fullfile(processed_pth,subdir{sub},'redfspmeeg');
    D = spm_eeg_load(infile);
    D = D.montage('switch',0);
    
    % Remove headpoints around face (y>0 & z<0), particularly important if MRI de-faced
    fid = D.fiducials;
    fid.pnt(find(fid.pnt(:,2)>0 & fid.pnt(:,3)<0),:)=[];
    D=fiducials(D,fid); D.save
    
    %D = rmfield(D,'inv');
    
    T1file = fullfile(processed_pth,subdir{sub},[subdir{sub} '_ses-meg1_T1w.nii']);
    if exist(T1file,'file')
        D = spm_eeg_inv_mesh_ui(D,1,T1file,2);
        
        V = spm_vol(T1file);
        fids = spm_jsonread(fullfile(bidspth,subdir{sub},'ses-meg1','anat',[subdir{sub} '_ses-meg1_T1w.json']));
        
        mrifid = [];
        megfid = D.fiducials;
        mrifid.fid.label = {'Nasion';'LPA';'RPA'};
        nasion = V.mat*[fids.AnatomicalLandmarkCoordinates.NAS; 1];    nasion = nasion(1:3)';
        lpa    = V.mat*[fids.AnatomicalLandmarkCoordinates.LPA; 1];    lpa    = lpa(1:3)';
        rpa    = V.mat*[fids.AnatomicalLandmarkCoordinates.RPA; 1];    rpa    = rpa(1:3)';
%         nasion = V.mat*[fids.AnatomicalLandmarkCoordinates.Nasion; 1]; nasion = nasion(1:3)';
%         lpa    = V.mat*[fids.AnatomicalLandmarkCoordinates.LPA; 1];    lpa    = lpa(1:3)';
%         rpa    = V.mat*[fids.AnatomicalLandmarkCoordinates.RPA; 1];    rpa    = rpa(1:3)';
        mrifid.fid.pnt = [nasion; lpa; rpa];
        mrifid.pnt = D.inv{1}.mesh.fid.pnt;
        D = spm_eeg_inv_datareg_ui(D, 1, megfid, mrifid, UseHPs);
        if UseHPs, D.inv{1}.comment = 'With headpoints'; else, D.inv{1}.comment = 'SPM fids only'; end
        D.save;
        
    else
        D = spm_eeg_inv_mesh_ui(D,1,1,2);
        mrifid = [];
        for f=1:3
            mrifid.fid.label{f} = D.inv{1}.mesh.fid.fid.label{f};
            mrifid.fid.pnt(f,:) = D.inv{1}.mesh.fid.fid.pnt(f,:);
        end
        megfid = D.fiducials;
        megfid.fid.label{find(strcmp([megfid.fid.label],'LPA'))} = 'lpa';
        megfid.fid.label{find(strcmp([megfid.fid.label],'RPA'))} = 'rpa';
        megfid.fid.label{find(strcmp([megfid.fid.label],'Nasion'))} = 'nas';
        D = spm_eeg_inv_datareg_ui(D, 1, megfid, mrifid, 0);
        D.save;
    end

    % Rectify issue where EEG modality still appears
    if (length(D.inv{1}.datareg) == 2)
        if strcmp(D.inv{1}.datareg(1).modality, 'EEG')
            D.inv{1}.datareg(1) = [];
        elseif strcmp(D.inv{1}.datareg(2).modality, 'EEG')
            D.inv{1}.datareg(2) = [];
        else
            error('unexpected');
        end
    end
    
    D.inv{1}.forward(1).voltype = 'Single Shell';
    D = spm_eeg_inv_forward(D);
    D.save;   
    
end

%% Rename MEGPLANAR channels
for sub=1:length(subs)
    disp(sub);
    infile = fullfile(processed_pth,subdir{sub},'redfspmeeg');
    D = spm_eeg_load(infile);
    D = chantype(D,indchantype(D,'MEGGRADPLANAR'),'MEGPLANAR');
    D.save;
end   

%% Beamforming and Extract ROIs using OSL

% p           = parcellation(fullfile('fMRI_parcellation_ds8mm.nii.gz'));
% mni_coords  = p.template_coordinates;
% 
% for sub = 1:1
% 
% % parfor sub = 1:length(subs)
%     
%     infile = fullfile(processed_pth,subdir{sub},'effdspmeeg');
%     D = spm_eeg_load(infile);
%     
%     % Run Beamforming
%     
%     S = struct;
% %     S.modalities        = {'MEG','MEGPLANAR'};
% %     S.modalities        = {'MEG'};
%     S.modalities        = {'MEGMAG','MEGGRADPLANAR'};
%     S.fuse              = 'all';
%     S.timespan          = [0 Inf];
%     S.pca_order         = 50;
%     S.type              = 'Scalar';
%     S.inverse_method    = 'beamform';
%     S.prefix            = 'b';
%     
%     D = osl_inverse_model(D,mni_coords,S);
%     
%     % Select montage
%     D = D.montage('switch',1);
%     
%     % Extract ROI (Region Of Interest)
%     D = ROInets.get_node_tcs(D,p.to_matrix(p.binarize),'pca');
%     
%     % Save the data
%     D.save;
%     
% end
