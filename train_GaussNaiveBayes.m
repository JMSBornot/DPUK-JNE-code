function mdl = train_GaussNaiveBayes(X,Y,~,~,isCategoricalPredictor)
% mdl - Bayesian trained model
if ~exist('isCategoricalPredictor','var')
    isCategoricalPredictor = [];
end

distributionNames =  repmat({'Normal'}, 1, size(X,2));
distributionNames(isCategoricalPredictor) = {'mvmn'};

mdl = fitcnb(X,Y,'DistributionNames', distributionNames, 'ClassNames', [1; 2]);