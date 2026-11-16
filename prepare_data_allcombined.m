% prepare_data_allcombined

%% Save all results to Excel table for N-way ANOVA analyses (SPSS)
NMC = 100;

type = 'cvStats';
% type = 'honStats';

colnamestat = ["accuracy" "sensitivity" "specificity" "AUC"];

metall = {'GaussNaiveBayes' 'KernelNaiveBayes' 'WideNeuralNet' 'BilayeredNeuralNet' 'SubspDiscEnsemble' 'KSVM_BayesianOptim' 'GLMNET'};
invall = {'Sensor' 'COH', 'MSP', 'EBB', 'LCMV', 'eLORETA'};

code_meth = repmat(1:length(metall), [NMC 1 length(invall)]);
code_invsol = repmat(reshape(1:length(invall),[1 1 length(invall)]), [NMC length(metall) 1]);

tblall = zeros(NMC, length(metall), length(invall));
for iind = 1:length(colnamestat)
    for jind = 1:length(invall)
        fname = sprintf('results_allcombined_zscores_%s_Relieff_K10.mat', invall{jind})
        load(fname);
        for m = 1:length(metall)-1
            tblall(:,m,jind) = eval(sprintf('%s_%s(:,%d)',type,metall{m},iind));
        end

        fname = sprintf('glmnet_allcombined_uncorrected_%s_K10.mat', invall{jind})
        load(fname, "x");
        switch colnamestat(iind)
            case "accuracy"
                if strcmp(type,'honStats')
                    tblall(:,m+1,jind) = x.("Holdout Accuracy");
                else % cvStats
                    tblall(:,m+1,jind) = x.("CV Accuracy");
                end
            case "sensitivity"
                if strcmp(type,'honStats')
                    tblall(:,m+1,jind) = x.("Holdout Sensitivity");
                else % cvStats
                    tblall(:,m+1,jind) = x.("CV Sensitivity");
                end
            case "specificity"
                if strcmp(type,'honStats')
                    tblall(:,m+1,jind) = x.("Holdout Specificity");
                else % cvStats
                    tblall(:,m+1,jind) = x.("CV Specificity");
                end
            case "AUC"
                if strcmp(type,'honStats')
                    tblall(:,m+1,jind) = x.("Holdout AUC");
                else % cvStats
                    tblall(:,m+1,jind) = x.("CV AUC");
                end
        end

    end
    fname = sprintf('X_SPSS_allcombined_Nway_%s_%s.xlsx',type,colnamestat(iind));
    writecell([{'Stat' 'ClassMethods' 'InvSolMethods'}; num2cell([tblall(:) code_meth(:) code_invsol(:)])], fname);
    writecell(metall, fname, 'Sheet', 'ClassMethods');
    writecell(invall, fname, 'Sheet', 'InvSolMethods');
end