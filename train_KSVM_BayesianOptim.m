function mdl = train_KSVM_BayesianOptim(X,Y,Niter,K)
% mdl - Bayesian trained model

kernel = optimizableVariable('KernelFunction', {'linear','gaussian','rbf','polynomial'}, 'Type', 'categorical');
scale = optimizableVariable('KernelScale', [1e-1,1e1]);
boxconst = optimizableVariable('BoxConstraint', [1e-1,1e1]);
c = cvpartition(length(Y), 'Kfold', K);
fun = @(x)kfoldLoss(fitcsvm(X,Y,'CVPartition',c,'KernelFunction',char(x.KernelFunction),...
    'KernelScale',x.KernelScale,'BoxConstraint',x.BoxConstraint));
results = bayesopt(fun, [kernel,scale,boxconst], 'MaxObjectiveEvaluations', Niter, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', 'Verbose', 0, 'PlotFcn', []);
mdl = fitcsvm(X, Y, 'KernelFunction', char(results.XAtMinObjective.KernelFunction), ...
    'KernelScale', results.XAtMinObjective.KernelScale,'BoxConstraint', results.XAtMinObjective.BoxConstraint);