function mdl = train_WideNeuralNet(X,Y,~,~,~)
% mdl - Bayesian trained model
mdl = fitcnet(X,Y,'LayerSizes',100,'Activations','relu','Lambda',0,'IterationLimit',1000,'Standardize',false,'ClassNames',[1; 2]);