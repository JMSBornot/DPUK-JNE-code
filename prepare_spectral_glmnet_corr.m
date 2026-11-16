% prepare_spectral_glmnet_corr

% for inv = {'Sensor','MSP','EBB','COH','eLORETA','LCMV'}
%     for ch = {'MEG','MEGPLANAR'}
%         for cut = {'0','0.05','0.1','0.15','0.2'}
%             fname = fullfile('S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Linux\', ...
%                 sprintf('glmnet_uncorrected_%s_%s_K10_NMC20_alpha1_signcorr%s.mat',ch{1},inv{1},cut{1}));
%             disp(fname);
%             if exist(fname,'file')
%                 load(fname);
%                 accHO=x.('Holdout Accuracy');
%                 accCV=x.('CV Accuracy');
%                 disp([mean(accHO) std(accHO) mean(accCV) std(accCV)]);
%             else
%                 disp(NaN);
%             end
%         end
%     end
% end

%% Save all results to Excel table for N-way ANOVA analyses (SPSS)
NMC = 20;

% type = 'CV';
type = 'Holdout';

colnamestat = {"Accuracy" "Sensitivity" "Specificity" "PPV" "NPV" "AUC" "F1" "MCC"};

modall = {'MEG', 'MEGPLANAR'};
invall = {'Sensor', 'MSP', 'EBB', 'COH', 'eLORETA', 'LCMV'};
cutoff = {'0', '0.05', '0.1', '0.15', '0.2'};

code_mod    = repmat(reshape(1:length(modall), [1 length(modall)]),      [NMC        1       length(invall) length(cutoff)]);
code_invsol = repmat(reshape(1:length(invall), [1 1 length(invall)]),    [NMC length(modall)        1       length(cutoff)]);
code_cutoff = repmat(reshape(1:length(cutoff), [1 1 1 length(cutoff)]),  [NMC length(modall) length(invall)        1]);

tblall = NaN(NMC, length(modall), length(invall), length(cutoff));

dname = 'S:\0539 - Finding Biomarker for Healthy Ageing - Tracking Brain Regional Changes for B\Linux\';
for istat = 1:length(colnamestat)
    for imod = 1:length(modall)
        for iinv = 1:length(invall)
            for icut = 1:length(cutoff)
                fname = fullfile(dname, sprintf('glmnet_uncorrected_%s_%s_K10_NMC20_alpha1_signcorr%s.mat',modall{imod},invall{iinv},cutoff{icut}));
                if exist(fname,'file')
                    load(fname);
                    switch (colnamestat{istat})
                        case "F1"
                            TPR = x.(sprintf('%s Sensitivity',type));
                            PPV = x.(sprintf('%s PPV',type));
                            F1 = 2*(PPV.*TPR)./(PPV + TPR);
                            tblall(:,imod,iinv,icut) = F1;
                        case "MCC"
                            TPR = x.(sprintf('%s Sensitivity',type));
                            TNR = x.(sprintf('%s Specificity',type));
                            PPV = x.(sprintf('%s PPV',type));
                            NPV = x.(sprintf('%s NPV',type));
                            MCC = sqrt(TPR.*TNR.*PPV.*NPV) - sqrt((1-TPR).*(1-TNR).*(1-PPV).*(1-NPV));
                            tblall(:,imod,iinv,icut) = 0.5*(1 + MCC);
                        otherwise
                            tblall(:,imod,iinv,icut) = x.(sprintf('%s %s',type,colnamestat{istat}));
                    end
                end
            end
        end
    end
    fname = sprintf('X_SPSS_glmnetCorr_spectral_Nway_%s_%s.xlsx',type,colnamestat{istat});
    writecell([{'Stat' 'Modalities' 'InvSolMethods' 'Cutoff'}; num2cell([tblall(:) code_mod(:) code_invsol(:) code_cutoff(:)])], fname);
    writecell(modall, fname, 'Sheet', 'Modalities');
    writecell(invall, fname, 'Sheet', 'InvSolMethods');
    writecell(cutoff, fname, 'Sheet', 'Cutoff');
end