%% Save all results to Excel table for N-way ANOVA analyses (SPSS)
NMC = 100;

type = 'cvStats';
% type = 'honStats';

colnamestat = ["accuracy" "sensitivity" "specificity" "AUC"];

metall = {'GaussNaiveBayes' 'KernelNaiveBayes' 'WideNeuralNet' 'BilayeredNeuralNet' 'SubspDiscEnsemble' 'KSVM_BayesianOptim' 'GLMNET'};
norall = {'fcent1_fnorm1' 'residuals' 'zscores'};

code_meth = repmat(1:length(metall), [NMC 1 length(norall)]);
code_norm = repmat(reshape(1:length(norall),[1 1 length(norall)]), [NMC length(metall) 1]);

tblall = zeros(NMC, length(metall), length(norall));
for iind = 1:length(colnamestat)
    for kind = 1:length(norall)
        fname = sprintf('results_aparcaseg_%s.mat', norall{kind})
        load(fname);
        for m = 1:length(metall)-1
            tblall(:,m,kind) = eval(sprintf('%s_%s(:,%d)',type,metall{m},iind));
        end

        fname = sprintf('results_aparcaseg_auc_%s_K10.mat', norall{kind})
        load(fname, "x");
        switch colnamestat(iind)
            case "accuracy"
                if strcmp(type,'honStats')
                    tblall(:,m+1,kind) = x.("Holdout Accuracy");
                else % cvStats
                    tblall(:,m+1,kind) = x.("CV Accuracy");
                end
            case "sensitivity"
                if strcmp(type,'honStats')
                    tblall(:,m+1,kind) = x.("Holdout Sensitivity");
                else % cvStats
                    tblall(:,m+1,kind) = x.("CV Sensitivity");
                end
            case "specificity"
                if strcmp(type,'honStats')
                    tblall(:,m+1,kind) = x.("Holdout Specificity");
                else % cvStats
                    tblall(:,m+1,kind) = x.("CV Specificity");
                end
            case "AUC"
                if strcmp(type,'honStats')
                    tblall(:,m+1,kind) = x.("Holdout AUC");
                else % cvStats
                    tblall(:,m+1,kind) = x.("CV AUC");
                end
        end
    end

    fname = sprintf('X_SPSS_aparcaseg_Nway_%s_%s.xlsx',type,colnamestat(iind));
    writecell([{'Stat' 'ClassMethods' 'Normalization'}; ...
        num2cell([tblall(:) code_meth(:) code_norm(:)])], fname);
    writecell(metall, fname, 'Sheet', 'ClassMethods');
    writecell(norall, fname, 'Sheet', 'Normalization');
end