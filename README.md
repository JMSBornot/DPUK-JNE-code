# BioFIND MEG/MRI biomarker analysis — DPUK / JNE

Research code for analysing magnetoencephalography (MEG) and structural magnetic resonance imaging (MRI) data from the **BioFIND** cohort, developed and adapted in the course of **Alwani Liyana Ahmad's PhD research**. The principal application is distinguishing healthy controls (HC) from participants with mild cognitive impairment (MCI), with particular emphasis on MEG spectral biomarkers, source reconstruction, machine learning, and multimodal MEG–MRI integration.

**Associated publication:** Ahmad, A. L., Sánchez-Bornot, J. M., Sotero, R. C., Coyle, D. H., Idris, Z., & Faye, I. (2026). *Towards improving Alzheimer's intervention: a machine learning approach for biomarker detection through combining MEG and MRI pipelines.* **Journal of Neural Engineering**. [https://doi.org/10.1088/1741-2552/aebb66](https://doi.org/10.1088/1741-2552/aebb66)

> **Scope and status:** This is a collection of research scripts, not a packaged or automatically tested application. Some files are earlier benchmark implementations, supporting utilities, or exploratory analyses. Configuration and access to the authorised research data are necessary before execution. The publication is the definitive reference for the reported study design and results.

## Research context

The BioFIND dataset contains eyes-closed resting-state MEG recordings from **324 participants (166 HC; 158 MCI)** collected at two sites, together with structural MRI where available. The data are organised using the Brain Imaging Data Structure (BIDS) and made available for authorised analysis through the secure **Dementias Platform UK (DPUK)** environment.

This repository supports comparisons of:

- Sensor-space MEG features from magnetometers and planar gradiometers.
- Source-space MEG features obtained with alternative inverse methods, including **COH, MSP, EBB, LCMV and eLORETA**.
- Relative spectral power in conventional delta, theta, alpha, beta and gamma bands.
- Structural MRI-derived regional measurements, and combined MEG–MRI predictors.
- Classification methods such as SVM, naïve Bayes, KNN, ensemble methods and regularised logistic regression (**GLMNET**).
- Repeated and nested cross-validation experiments and statistical summaries.

The repository also contains **functional connectivity** analyses (amplitude-envelope correlation, coherence, imaginary coherency and debiased weighted phase-lag index). These are related research workflows; they should **not** all be assumed to form part of the associated JNE spectral-biomarker publication.

## Processing workflow

~~~text
Authorised BioFIND BIDS data (MEG and, where available, T1 MRI)
                         |
          MATLAB / SPM12 / OSL preprocessing
       filtering, 1-s epoching, artefact rejection
                         |
             Coregistration and source models
                         |
           SPM inversion / DAiSS beamforming
      COH, MSP, EBB, LCMV, eLORETA; source time series
                         |
                 Feature extraction
         MEG spectral power / functional connectivity
                         |
             MRI FreeSurfer-derived features
                         |
      Feature tables / MEG-only or MEG + MRI designs
                         |
      MATLAB classifiers or R / GLMNET experiments
                         |
          Cross-validation, metrics and plots
~~~

This diagram summarises the available components; it is **not** a claim that a single script runs the entire pipeline.

## Repository guide

| Stage | Main files | Purpose |
| --- | --- | --- |
| BIDS organisation | [Xnat2Bids.m](Xnat2Bids.m), [spm_BIDS.m](spm_BIDS.m) | Historical XNAT-to-BIDS conversion and BIDS discovery; see cautions below. |
| MEG preprocessing | [preproc_beamform_ROI.m](preproc_beamform_ROI.m) | Import BioFIND MEG, filter and downsample, create epochs, detect artefacts, and coregister MEG/MRI or an anatomical template. |
| Source reconstruction | [run_biofind_spm_invsol.m](run_biofind_spm_invsol.m), [run_biofind_spm_invsol_LCMV.m](run_biofind_spm_invsol_LCMV.m), [run_biofind_spm_invsol_eLORETA.m](run_biofind_spm_invsol_eLORETA.m), [run_spm_invsol.m](run_spm_invsol.m) | SPM inverse solutions, DAiSS-based LCMV/eLORETA processing, and extraction of source activity at cortical sampling points. |
| Spectral features | [feature_extraction_biofind_benchmark.m](feature_extraction_biofind_benchmark.m), [feature_extraction_test.m](feature_extraction_test.m) | Compute sensor-/source-level relative power features and benchmark analyses. |
| Connectivity features | [feature_extraction_AEC.m](feature_extraction_AEC.m), [feature_extraction_COH.m](feature_extraction_COH.m) | Amplitude-envelope correlation; coherence, imaginary coherency and debiased wPLI. |
| MRI morphometry | [run_freesurfer_preproc.sh](run_freesurfer_preproc.sh), [run_freesurfer_postproc.sh](run_freesurfer_postproc.sh) | Run FreeSurfer reconstruction and extract anatomical summary tables. |
| Feature preparation | [run_features_classification_K10.m](run_features_classification_K10.m), [run_features_classification_combined.m](run_features_classification_combined.m), [run_features_connectivity.m](run_features_connectivity.m) | Prepare feature matrices and spreadsheet exports for MEG, connectivity and combined MEG–MRI experiments. |
| MATLAB classification | [run_classification_K10.m](run_classification_K10.m), [class_learn_app_auto.m](class_learn_app_auto.m), [class_learn_comb_auto.m](class_learn_comb_auto.m), [automated_feature_selection.m](automated_feature_selection.m), `train_*.m` | Cross-validation, feature selection and alternative classifier training functions. |
| R / GLMNET | [eval_megfeatures_glmnet.R](eval_megfeatures_glmnet.R), [eval_megfeatures_glmnet_alpha_corr.R](eval_megfeatures_glmnet_alpha_corr.R), [eval_megmrifeatures_glmnet.R](eval_megmrifeatures_glmnet.R), `nested_*glmnet*.R` | Repeated nested cross-validation with regularised/relaxed logistic regression; variants include MEG-only, feature screening, and MEG–MRI. |
| Batch evaluation | [runall_spectral_corr.sh](runall_spectral_corr.sh), [runall_FC_corr.sh](runall_FC_corr.sh), `runall_*.sh` | Shell wrappers for repeated R classification experiments. |
| Results and figures | [prepare_spectral_glmnet_corr.m](prepare_spectral_glmnet_corr.m), [prepare_FC_glmnet_corr.m](prepare_FC_glmnet_corr.m), [brainplot.m](brainplot.m), [barerrorplot.m](barerrorplot.m) | Collate performance metrics and prepare statistical summaries/visualisations. |

Additional `*_adni` files, other experimental classifiers and plotting tests are retained as supporting or historical research code; they are not the primary BioFIND/JNE entry points.

## Data access and restrictions

**No BioFIND participant-level data are distributed by this repository.** The BioFIND source recordings, MRI scans, metadata, derived subject-level feature tables and any other restricted outputs must be obtained and handled under the applicable DPUK approval and data-use agreements.

- BioFIND description and access information: [Vaghari et al., NeuroImage (2022)](https://doi.org/10.1016/j.neuroimage.2022.119344).
- DPUK access information: [Dementias Platform UK application portal](https://portal.dementiasplatform.uk/Apply).
- Original BioFIND processing and benchmark repository: [delshadv/BioFIND-data-paper](https://github.com/delshadv/BioFIND-data-paper).

Do not upload raw or derived restricted data, potentially identifying participant metadata, credentials, or unauthorised analysis exports to a public GitHub repository. Follow DPUK's approved file import/export procedures; the secure workspace may not permit direct internet access.

## Software requirements

The required environment depends on which part of the pipeline is used:

- **MATLAB** with relevant Signal Processing and Statistics and Machine Learning functionality; some scripts also use `parfor` (Parallel Computing Toolbox).
- **SPM12** for M/EEG processing, coregistration and inversion; **DAiSS** for the LCMV/eLORETA scripts.
- **Oxford Software Library (OSL)** and **FieldTrip** for relevant preprocessing and connectivity functions; several scripts reference OSL/ROInets functions.
- **FreeSurfer** for MRI cortical reconstruction and anatomical feature extraction.
- **R** with the packages `readxl`, `R.matlab`, `dplyr`, `glmnet`, `caret`, `ROCR` and `pROC`, plus a Bash environment for `runall_*.sh`.

Exact tested software versions and a fully reproducible environment manifest have **not** been established in this repository. The included [install_R.sh](install_R.sh) documents an earlier conda-based R 4.3.2 setup, but contains user-specific paths and does not install every package used by the R scripts (notably `R.matlab`). Review and adapt it rather than running it unchanged.

## Getting started

1. Obtain authorised access to the BioFIND dataset within DPUK and ensure the necessary software has been installed or approved in that environment.
2. Copy this code into the approved workspace. If GitHub is inaccessible from DPUK, use its approved import mechanism rather than assuming that `git clone` will work.
3. **Edit the hard-coded paths** before running any analysis. Several scripts expect Windows network drives such as `S:/BioFIND - BioFIND/BioFIND` and `P:/alahmad/Matlab/BioFIND-data-paper`; shell scripts may refer to `/home/alahmad/...`. Keep a separate processed-output directory.
4. Check external inputs. Some scripts require `participants-imputed.tsv`, preprocessed SPM files, `kmedoids_data.mat` (500 cortical sampling points), or MRI spreadsheets such as `Combine_aparcaseg_proc.xlsx`. These are **not included** here.
5. Select the appropriate script family for the chosen analysis. A common **manual** sequence is MEG preprocessing (`preproc_beamform_ROI.m`), source inversion (`run_biofind_spm_invsol*.m`), feature extraction, feature-table export and finally classification. Review and execute sections individually; certain scripts contain exploratory sections, commented operations or `keyboard` statements.

### Example: R / GLMNET on an existing feature table

After configuring the data path within the R script, and after creating an authorised table named `features_uncorrected_MEG_LCMV.xlsx` containing a `Group` column and numerical predictors, run from the repository directory:

~~~bash
Rscript eval_megfeatures_glmnet.R uncorrected_MEG_LCMV 10 20 auc 1
~~~

This requests 10-fold evaluation, 20 Monte Carlo repetitions, AUC-based tuning and `alpha = 1` (L1 regularisation). The wrapper sources `nested_kfold_glmnet.R` and writes output files in R and MATLAB formats. It is **an example of the command interface, not a guaranteed end-to-end reproduction**: the input data must already have been produced and the hard-coded location adapted.

The related correlation-screening wrapper accepts a sixth argument, for example:

~~~bash
Rscript eval_megfeatures_glmnet_alpha_corr.R coh_MEG_LCMV 10 20 auc 1 0.20
~~~

Here the feature-table label and correlation cutoff are illustrative; the relevant input table must exist. See the methodological warning below before using these estimates in scientific reports.

## Reproducibility and known caveats

- **Check input conventions:** In several MATLAB scripts, `MEG` denotes the magnetometer feature set (102 channels) while `MEGPLANAR` denotes planar gradiometers (204 channels). Validate SPM channel labels, anatomical availability and participant order before comparing results.
- **Edit hard-coded overrides:** Some functions that accept a `type_data` argument (for example, `run_features_classification_K10.m`, `run_classification_K10.m` and `run_features_connectivity.m`) subsequently set `type_data = 'Sensor'` internally. Remove or adjust that override when processing other inverse solutions.
- **Review batch scripts:** `runall_FC_corr.sh` includes a reference to `eval_megfeatures_glmnet_alpha_corrv.R`, which is not present; confirm the intended filename before running the batch.
- **Avoid data leakage:** In `nested_kfold_glmnet_alpha_corr.R`, correlation-based screening/sign constraints are computed from the full input data **before** the outer folds are created. That can introduce label leakage into held-out evaluation. For new unbiased analyses, fit any label-informed feature selection using only each outer training fold. Likewise, review any whole-sample confound regression performed before cross-validation.
- **Do not blindly rerun dataset conversion:** `Xnat2Bids.m` contains `movefile` commands that may relocate source files. It is a historical conversion script, **not** a recommended routine preprocessing step on an existing DPUK dataset.
- **Interpret validation correctly:** Nested and repeated cross-validation are internal validation strategies, not evidence of external clinical validation. Results depend on cohort composition, feature preprocessing, split generation, and software versions.
- **Third-party provenance and licensing:** `spm_BIDS.m` contains copyright and attribution notices for the Wellcome Trust Centre for Neuroimaging; other files build on the original BioFIND examples and external toolboxes. Retain notices and verify redistribution permissions before applying a repository-wide licence.

## Publications and attribution

1. **Ahmad, A. L., Sánchez-Bornot, J. M., Sotero, R. C., Coyle, D. H., Idris, Z., & Faye, I. (2026).** Towards improving Alzheimer's intervention: a machine learning approach for biomarker detection through combining MEG and MRI pipelines. *Journal of Neural Engineering*. [doi:10.1088/1741-2552/aebb66](https://doi.org/10.1088/1741-2552/aebb66).
2. **Vaghari, D., Bruna, R., Hughes, L. E., Nesbitt, D., Tibon, R., Rowe, J. B., Maestu, F., & Henson, R. N. (2022).** A multi-site, multi-participant magnetoencephalography resting-state dataset to study dementia: The BioFIND dataset. *NeuroImage, 258*, 119344. [doi:10.1016/j.neuroimage.2022.119344](https://doi.org/10.1016/j.neuroimage.2022.119344).

The repository combines scripts developed or adapted for the PhD work with benchmark-derived and third-party components. Please cite **both** the applicable analysis publication and the original BioFIND dataset paper when using the data or workflows, and follow the individual toolboxes' attribution requirements.

## Licensing and contact

**No open-source licence has yet been declared for this repository.** Public visibility does not itself grant permission to copy, modify or redistribute the files. Before selecting a licence, review the provenance and redistribution terms of imported or modified third-party code.

For research questions or suggested improvements, please use the [repository issue tracker](https://github.com/JMSBornot/DPUK-JNE-code/issues). For access to BioFIND participant data, apply through DPUK rather than requesting the data through GitHub.
