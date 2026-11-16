function mdl = train_SubspDiscEnsemble(X,Y,~,~,~)
% mdl - Bayesian trained model
mdl = fitcensemble(X,Y,'Method','Subspace','NumLearningCycles',30,'Learners','discriminant','ClassNames',[1;2]);