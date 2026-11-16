function zscore = barerrorplot(X, dim, ntop, varnames)
% X - 2D matrix of dimensions measurements x repetitions, or its transpose
% dim - dimension for which to apply mean and std operations

Nvars = size(X,3-dim);
assert(Nvars == length(varnames), 'The number of features in varnames must match the corresponding dimension in X');

xm = mean(X,dim);
xs = std(X,0,dim);
xb = xs/sqrt(size(X,dim)); % error bar
figure; bar(1:length(xm), xm)
hold on;
herr = errorbar(1:length(xm), xm, xb, xb);
herr.LineStyle = 'None';
% herr.LineWidth = 2;
herr.Color=[0 0 0];
hold off;
set(gca,'fontsize',16)

zscore = xm./xb;
zscore(isnan(zscore)) = 0;

[rank,ind] = sort(abs(zscore),'descend');
% figure; barh(rank(1:ntop));
figure; barh(zscore(ind(1:ntop)));
set(gca, 'ydir', 'reverse');
set(gca,'fontsize',16)
labels = varnames(ind(1:ntop));

set(gca, 'YTick', 1:ntop);
set(gca, 'YTickLabel', labels);
set(gca, 'YTickLabel', strrep(labels,'_','\_'));