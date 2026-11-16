function mdl = train_SubspDiscEnsemble_BayesianOptim(X,Y,~,~,~)
% mdl - Bayesian trained model
mdl = fitcensemble(X,Y,'Method','Subspace','NumLearningCycles',30,'Learners','discriminant','ClassNames',[1;2]);


method = optimizableVariable('Method', {'RUSBoost','LogitBoost','AdaBoostM1','Bag'}, 'Type', 'categorical');
num = optimizableVariable('NumLearningCycles', [5,70], 'Type', 'integer');

scale = optimizableVariable('KernelScale', [1e-1,1e1]);
boxconst = optimizableVariable('BoxConstraint', [1e-1,1e1]);
c = cvpartition(length(Y), 'Kfold', K-1);

fun = @(x)kfoldLoss(fitcsvm(X,Y,'CVPartition',c,'KernelFunction',char(x.KernelFunction),...
    'KernelScale',x.KernelScale,'BoxConstraint',x.BoxConstraint));
results = bayesopt(fun, [kernel,scale,boxconst], 'MaxObjectiveEvaluations', Niter, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', 'Verbose', 0);
mdl = fitcsvm(X, Y, 'KernelFunction', char(results.XAtMinObjective.KernelFunction), ...
    'KernelScale', results.XAtMinObjective.KernelScale,'BoxConstraint', results.XAtMinObjective.BoxConstraint);