function mdl = train_KernelNaiveBayes(X,Y,~,~,isCategoricalPredictor)
% mdl - Bayesian trained model
if ~exist('isCategoricalPredictor','var')
    isCategoricalPredictor = [];
end

distributionNames =  repmat({'Kernel'}, 1, size(X,2));
distributionNames(isCategoricalPredictor) = {'mvmn'};

mdl = fitcnb(X,Y,'Kernel','Normal','Support','Unbounded','DistributionNames',distributionNames);