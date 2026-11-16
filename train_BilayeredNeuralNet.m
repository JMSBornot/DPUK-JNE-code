function mdl = train_BilayeredNeuralNet(X,Y,~,~,~)
% mdl - Bayesian trained model
mdl = fitcnet(X,Y,'LayerSizes',[10 10],'Activations','relu','Lambda',0,'IterationLimit',1000,'Standardize',false,'ClassNames',[1; 2]);