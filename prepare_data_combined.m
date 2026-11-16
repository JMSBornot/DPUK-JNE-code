% prepare_data_combined

%% Save all results to Excel table for N-way ANOVA analyses (SPSS)
NMC = 100;

type = 'cvStats';
% type = 'honStats';

colnamestat = ["accuracy" "sensitivity" "specificity" "AUC"];

metall = {'GaussNaiveBayes' 'KernelNaiveBayes' 'WideNeuralNet' 'BilayeredNeuralNet' 'SubspDiscEnsemble' 'KSVM_BayesianOptim' 'GLMNET'};
modall = {'MEG', 'MEGPLANAR'};
invall = {'Sensor' 'COH', 'MSP', 'EBB', 'LCMV', 'eLORETA'};

code_meth = repmat(1:length(metall), [NMC 1 length(modall) length(invall)]);
code_mod = repmat(reshape(1:length(modall),[1 1 length(modall)]), [NMC length(metall) 1 length(invall)]);
code_invsol = repmat(reshape(1:length(invall),[1 1 1 length(invall)]), [NMC length(metall) length(modall) 1]);

tblall = zeros(NMC, length(metall), length(modall), length(invall));
for iind = 1:length(colnamestat)
    for jind = 1:length(invall)
        for lind = 1:length(modall)
            fname = sprintf('results_combined_uncorrected_%s_%s_Relieff_K10.mat', invall{jind}, modall{lind})
            load(fname);
            for m = 1:length(metall)-1
                tblall(:,m,lind,jind) = eval(sprintf('%s_%s(:,%d)',type,metall{m},iind));
            end

            fname = sprintf('glmnet_combined_uncorrected_%s_%s_K10.mat', modall{lind}, invall{jind})
            load(fname, "x");
            switch colnamestat(iind)
                case "accuracy"
                    if strcmp(type,'honStats')
                        tblall(:,m+1,lind,jind) = x.("Holdout Accuracy");
                    else % cvStats
                        tblall(:,m+1,lind,jind) = x.("CV Accuracy");
                    end
                case "sensitivity"
                    if strcmp(type,'honStats')
                        tblall(:,m+1,lind,jind) = x.("Holdout Sensitivity");
                    else % cvStats
                        tblall(:,m+1,lind,jind) = x.("CV Sensitivity");
                    end
                case "specificity"
                    if strcmp(type,'honStats')
                        tblall(:,m+1,lind,jind) = x.("Holdout Specificity");
                    else % cvStats
                        tblall(:,m+1,lind,jind) = x.("CV Specificity");
                    end
                case "AUC"
                    if strcmp(type,'honStats')
                        tblall(:,m+1,lind,jind) = x.("Holdout AUC");
                    else % cvStats
                        tblall(:,m+1,lind,jind) = x.("CV AUC");
                    end
            end
        end
    end
    fname = sprintf('X_SPSS_combined_Nway_%s_%s.xlsx',type,colnamestat(iind));
    writecell([{'Stat' 'ClassMethods' 'Modalities' 'InvSolMethods'}; num2cell([tblall(:) code_meth(:) code_mod(:) code_invsol(:)])], fname);
    writecell(metall, fname, 'Sheet', 'ClassMethods');
    writecell(modall, fname, 'Sheet', 'Modalities');
    writecell(invall, fname, 'Sheet', 'InvSolMethods');
end