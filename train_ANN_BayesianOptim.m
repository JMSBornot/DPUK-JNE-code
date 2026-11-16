function mdl = train_ANN_BayesianOptim(X,Y,Niter,K)
% mdl - Bayesian trained model

numLay = optimizableVariable('NumLayers', [1 3], 'Type', 'integer');
act = optimizableVariable('Activations', {'relu'  'tanh'  'sigmoid'}, 'Type', 'categorical');
lmbd = optimizableVariable('Lambda', [1e-6 0.5], 'Type', 'real', 'Transform', 'log');
L1Size = optimizableVariable('Layer_1_Size', [10 100], 'Type', 'integer');
L2Size = optimizableVariable('Layer_2_Size', [10 100], 'Type', 'integer');
L3Size = optimizableVariable('Layer_3_Size', [10 100], 'Type', 'integer');
c = cvpartition(length(Y), 'Kfold', K);

fun = @(x)kfoldLoss(fitcnet(X,Y,'CVPartition',c,'Standardize',false));
results = bayesopt(fun, [numLay,act,lmbd,L1Size,L2Size,L3Size], 'MaxObjectiveEvaluations', Niter, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', 'Verbose', 0, 'PlotFcn', []);
mdl = fitcnet(X, Y, 'Lambda', results.XAtMinObjective.Lambda, ...
    'Activations', char(results.XAtMinObjective.Activations), 'NumLayers', results.XAtMinObjective.NumLayers, ...
    'LayerSizes', [results.XAtMinObjective.Layer_1_Size, results.XAtMinObjective.Layer_2_Size, results.XAtMinObjective.Layer_3_Size]);