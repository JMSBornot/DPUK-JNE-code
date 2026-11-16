% NUM = csvread('X.csv');
% X = NUM(:,1:end-1);
% resp = NUM(:,end);


load('P:\alahmad\Matlab\BioFIND-data-paper\features_gamma_source_All_spect.mat', 'A_for_Cov', 'features', 'group_num', 'mri_num', 'type_invsol');
X = features(:,:,1);
resp = group_num;
[Nobs, Nvars] = size(X);

figure;

%% MRMR
[~,mrmr_scores] = fscmrmr(X,resp);
subplot 231;
bar(sort(mrmr_scores,'descend'), 'Horizontal', 'on');
title('MRMR scores');
set(gca, 'ydir', 'reverse');

%% Chi2
[~,chi2_scores] = fscchi2(X,resp);
subplot 232;
bar(sort(chi2_scores,'descend'), 'Horizontal', 'on');
title('Chi2 scores');
set(gca, 'ydir', 'reverse');

%% Relieff
[~,relieff_score] = relieff(X,resp,10);
subplot 233;
bar(sort(relieff_score,'descend'), 'Horizontal', 'on');
title('Relieff scores');
set(gca, 'ydir', 'reverse');

%% Anova
p = zeros(Nvars,1);
for i = 1:Nvars
    p(i) = anova1(X(:,i),resp,'off');
end
anova_score = -log(p);
subplot 234;
bar(sort(anova_score,'descend'), 'Horizontal', 'on');
title('Anova scores');
set(gca, 'ydir', 'reverse');

%% kruskalwallis
p = zeros(Nvars,1);
for i = 1:Nvars
    p(i) = kruskalwallis(X(:,i),resp,'off');
end
kw_score = -log(p);
subplot 235;
bar(sort(kw_score,'descend'), 'Horizontal', 'on');
title('kruskalwallis scores');
set(gca, 'ydir', 'reverse');