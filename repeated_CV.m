function accuracy = repeated_CV(A,kFolds,Nrun)

% This function calculates cross-validation accuracy
% using Support Vector Machines with linear kernel.
% The data is randomly split into "kFolds" partitions several times ("Nrun" times).
%
%
% A : input matrix [m n+1]; m: subjects (cases/observations), n: features
% last column must be targets (for e.g., Controls=1/MCI=2)
% kFolds : Number of folds
% Nrun : Number of runs to reapeate CV
% accuracy: holds cross-validation accuracies for each run
%
% Henson R.N 2020, Vaghari D 2020
% -------------------------------------------------------------------------

allData = A(:,1:end-1);
targets = A(:,end);

for rr = 1:Nrun  % can be for
    if (mod(rr-1,20) == 0), disp([rr Nrun]); end
    
%     kIdx = crossvalind('Kfold', length(targets), kFolds);
    cv = cvpartition(targets,'k',10);
    Score = zeros(1, kFolds);
    
    for k = 1:kFolds
        flag = cv.training(k);
        xtrain = allData(flag, :);
        ytrain = targets(flag);
        flag = cv.test(k);
        xtest = allData(flag, :);
        ytest = targets(flag);
        
        SVMmodel = fitcsvm(xtrain, ytrain, ...
              'KernelFunction', 'linear', 'KernelScale', 'auto', ...
              'BoxConstraint', 1,'Standardize', true,'solver','ISDA');
%       SVMmodel = fitclinear(xtrain, ytrain,'Solver','bfgs');
        Score(k) = loss(SVMmodel,xtest, ytest); % default: 'LossFun','classiferror'
        
    end
    
    accuracy(rr) = (mean(1-Score))*100;
end
