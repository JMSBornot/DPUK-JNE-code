function mdl = train_KNN_BayesianOptim(X,Y,Niter,K)
% mdl - Bayesian trained model

% num = optimizableVariable('NumNeighbors', [5,30], 'Type', 'integer');
num = optimizableVariable('NumNeighbors', [3,15], 'Type', 'integer');

dst = optimizableVariable('Distance', {'cityblock', 'chebychev', 'correlation', 'cosine', ...
    'euclidean', 'hamming', 'jaccard', 'mahalanobis', 'minkowski', 'seuclidean', 'spearman'}, 'Type', 'categorical');
c = cvpartition(length(Y), 'Kfold', K);
fun = @(x)kfoldLoss(fitcknn(X,Y,'CVPartition',c,'NumNeighbors',x.NumNeighbors,...
    'Distance',char(x.Distance),'NSMethod','exhaustive'));
results = bayesopt(fun, [num,dst], 'MaxObjectiveEvaluations', Niter, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', 'Verbose', 0, 'PlotFcn', []);
results.XAtMinObjective
mdl = fitcknn(X, Y, 'NumNeighbors', results.XAtMinObjective.NumNeighbors, ...
    'Distance', char(results.XAtMinObjective.Distance));