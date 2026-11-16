if ~exist('ft_defaults', 'file')
    addpath('C:\WORK\MATLAB\Toolboxes\fieldtrip-20210921');
end
ft_defaults;

wpli_type = 'debiased';
% wpli_type = 'original';

h1 = figure('Name', '6AB', 'NumberTitle', 'off');
h11 = figure('Name', '6AB_Extra', 'NumberTitle', 'off');

%% Simulate some data, 50 channels, no connectivity, 2 channels with high power
cfg_sim = [];
cfg_sim.method = 'ar';
cfg_sim.ntrials = 500;
cfg_sim.triallength = 1;
cfg_sim.fsample = 200;
cfg_sim.nsignal = 50;
cfg_sim.params(:,:,1) = diag(0.55*ones(cfg_sim.nsignal,1));
cfg_sim.params(:,:,2) = diag(-0.8*ones(cfg_sim.nsignal,1));
cfg_sim.noisecov = diag(0.05*ones(cfg_sim.nsignal,1)); 
cfg_sim.noisecov(16,16) = 1;
cfg_sim.noisecov(35,35) = 1;
data = ft_connectivitysimulation(cfg_sim);

% create the 'mixing' montage
montage = [];
montage.labelorg = data.label;
montage.labelnew = data.label;
montage.tra = convn(eye(50),hanning(31),'same');
data = ft_apply_montage(data, montage);

% calculate the fourier coefficients (non-parametric derivation of power)
cfg_freq = [];
cfg_freq.method = 'mtmfft';
cfg_freq.taper = 'dpss';
cfg_freq.output = 'fourier'; 
cfg_freq.tapsmofrq = 5;
cfg_freq.foilim = [0 100];
% cfg_freq.keeptrials = 'yes';
% cfg_freq.keeptapers = 'yes';
freq = ft_freqanalysis(cfg_freq, data);

% shortcut to obtain the cross-spectral density between all channel pairs
freq = ft_checkdata(freq, 'cmbstyle', 'fullfast');

% coherence calculation
cfg_conn = [];
cfg_conn.method = 'coh';
cfg_conn.complex = 'abs';
coh1 = ft_connectivityanalysis(cfg_conn, freq);

% imaginary part of coherency calculation
cfg_conn.complex = 'absimag';
icoh1 = ft_connectivityanalysis(cfg_conn, freq);

% === wpli_debiased ===
cfg_wpli = [];
cfg_wpli.method = 'mtmfft';

% cfg.taper = 'hanning';
cfg_wpli.taper = 'dpss';
cfg_wpli.tapsmofrq = 5;

cfg_wpli.output = 'powandcsd';
cfg_wpli.foilim = [0 100];
cfg_wpli.keeptrials = 'yes';
freq2 = ft_freqanalysis(cfg_wpli, data);
freq2 = ft_checkdata(freq2, 'cmbstyle', 'fullfast');

cfg2_conn = [];
if strcmp(wpli_type, 'debiased')
    cfg2_conn.method = 'wpli_debiased'; %#ok<*UNRCH>
else
    cfg2_conn.method = 'wpli';
end
wpli1 = ft_connectivityanalysis(cfg2_conn, freq2);

if strcmp(wpli_type, 'debiased')
    wpli1.wpli_debiasedspctrm(isnan(wpli1.wpli_debiasedspctrm)) = 0;
else
    wpli1.wplispctrm = abs(wpli1.wplispctrm);
    wpli1.wplispctrm(isnan(wpli1.wplispctrm)) = 0;
end

% === EIC ===
[Ne, Nc, ~, Nf] = size(freq2.crsspctrm); %#ok<*ASGLU>
icsp = permute(imag(freq2.crsspctrm), [4 1 2 3]); % Nf x Ne x Nc x Nc

denh = reshape(icsp, Nf, []);                     % Nf x ...
denh = reshape(hilbert(denh), [Nf Ne Nc Nc]);     % Nf x Ne x Nc x Nc
denh = squeeze(sqrt(mean(abs(denh).^2,2)));       % Nf x Nc x Nc
eic1 = squeeze(mean(icsp,2));                     % Nf x Nc x Nc
eic1 = abs(hilbert(eic1./denh));
eic1 = permute(eic1, [2 3 1]);                    % Nc x Nc x Nf
eic1(isnan(eic1)) = 0;

% % itmp = sqrt(Nf)*icsp./sqrt(sum(abs(icsp).^2));
% itmp = sqrt(Nf)*icsp./sqrt(sum(abs(hilbert(icsp)).^2));
% % itmp = icsp./std(icsp,0,1);
% 
% itmp = squeeze(mean(itmp,2)./std(itmp,0,2));
% itmp(isnan(itmp)) = 0;
% eic1 = abs(hilbert(itmp));
% eic1 = permute(eic1, [2 3 1]);                    % Nc x Nc x Nf

% === PLOTS ===
% these images now show the connectivity between all channel pairs, at 40
% Hz, and demonstrate the leakage (for the coherence metric) due to volume
% conduction.
figure(h1);
subplot 231;
hold on;
imagesc(coh1.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
hold off;
clim([0 1]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title('coherence','fontsize',25);
clim([0 1]);
colorbar('fontsize',25);

subplot 234;
hold on;
imagesc(icoh1.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
hold off;
clim([0 0.05]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title('imag(coh)','fontsize',25);
clim([0 1]);
colorbar('fontsize',25);

figure(h11);
subplot 231;
hold on;
if strcmp(wpli_type, 'debiased')
    imagesc(wpli1.wpli_debiasedspctrm(:,:,41));
else
    imagesc(wpli1.wplispctrm(:,:,41));
end
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
hold off;
clim([0 0.05]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title(sprintf('wpli(%s)',wpli_type),'fontsize',25);
clim([0 1]);
colorbar('fontsize',25);

subplot 234;
hold on;
imagesc(eic1(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
hold off;
clim([0 0.05]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title('EIC','fontsize',25);
clim([0 1]);
colorbar('fontsize',25);

%% Now create a connected 'data' using a generative model with cross terms:
% Figure 6B
cfg_sim.noisecov = diag(0.05*ones(cfg_sim.nsignal,1));
cfg_sim.noisecov(16,16) = 1;
cfg_sim.noisecov(35,35) = 1;
cfg_sim.params(16,35,1) = 0.25;
cfg_sim.params(16,35,2) = -0.1; %connect these sources, with a time lag
data = ft_apply_montage(ft_connectivitysimulation(cfg_sim), montage);

% Cross-spectral density computation
freq = ft_checkdata(ft_freqanalysis(cfg_freq, data), 'cmbstyle', 'fullfast');

% Coherence calculation
cfg_conn.complex = 'abs';
coh = ft_connectivityanalysis(cfg_conn, freq);
cfg_conn.complex = 'absimag';
icoh = ft_connectivityanalysis(cfg_conn, freq);

% === wpli_debiased ===
freq2 = ft_freqanalysis(cfg_wpli, data);
freq2 = ft_checkdata(freq2, 'cmbstyle', 'fullfast');
wpli = ft_connectivityanalysis(cfg2_conn, freq2);

if strcmp(wpli_type, 'debiased')
    wpli.wpli_debiasedspctrm(isnan(wpli.wpli_debiasedspctrm)) = 0;
else
    wpli.wplispctrm = abs(wpli.wplispctrm);
    wpli.wplispctrm(isnan(wpli.wplispctrm)) = 0;
end

% === EIC ===
[Ne, Nc, ~, Nf] = size(freq2.crsspctrm);
icsp = permute(imag(freq2.crsspctrm), [4 1 2 3]); % Nf x Ne x Nc x Nc

denh = reshape(icsp, Nf, []);                     % Nf x ...
denh = reshape(hilbert(denh), [Nf Ne Nc Nc]);     % Nf x Ne x Nc x Nc
denh = squeeze(sqrt(mean(abs(denh).^2,2)));       % Nf x Nc x Nc
eic = squeeze(mean(icsp,2));                      % Nf x Nc x Nc
eic = abs(hilbert(eic./denh));
eic = permute(eic, [2 3 1]);                      % Nc x Nc x Nf
eic(isnan(eic)) = 0;

% % itmp = sqrt(Nf)*icsp./sqrt(sum(abs(icsp).^2));
% itmp = sqrt(Nf)*icsp./sqrt(sum(abs(hilbert(icsp)).^2));
% % itmp = icsp./std(icsp,0,1);
% 
% itmp = squeeze(mean(itmp,2)./std(itmp,0,2));
% itmp(isnan(itmp)) = 0;
% eic = abs(hilbert(itmp));
% eic = permute(eic, [2 3 1]);                    % Nc x Nc x Nf

% === PLOTS ===
figure(h1);
subplot 232;
hold on;
imagesc(coh.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[16 16],'w--','linewidth',2);
% plot([16 35],[16 16],'wo','markerfacecolor','w');
hold off;
clim([0 1]);
axis square;
axis tight;
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title('coherence','fontsize',25);
colorbar('fontsize', 25);

subplot 233;
plot(coh.cohspctrm(16,:,41),'k','linewidth',1);
axis([1 50 0 1]);
ylabel('coherence','fontsize', 25);
xlabel('sensor','fontsize', 25);
ylim([0 1]);
set(gca,'Xtick',10:10:40,'tickdir','out','fontsize',25);

subplot 235;
hold on;
imagesc(icoh.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[16 16],'w--','linewidth',2);
% plot([16 35],[16 16],'wo','markerfacecolor','w');
hold off;
clim([0 1]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title('imag(coh)','fontsize',25);
colorbar('fontsize', 25);

subplot 236;
plot(icoh.cohspctrm(16,:,41),'k','linewidth',1);
axis([1 50 0 0.5]);
ylabel('imag(coh)','fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25);
ylim([0 1]);
set(gca,'Xtick',10:10:40,'tickdir','out','fontsize',25);

% === wpli ===
figure(h11);
subplot 232;
hold on;
if strcmp(wpli_type, 'debiased')
    imagesc(wpli.wpli_debiasedspctrm(:,:,41));
else
    imagesc(wpli.wplispctrm(:,:,41));
end
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[16 16],'w--','linewidth',2);
hold off;
clim([0 1]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title(sprintf('wpli(%s)',wpli_type),'fontsize',25);
colorbar('fontsize', 25);

subplot 233;
if strcmp(wpli_type, 'debiased')
    plot(wpli.wpli_debiasedspctrm(16,:,41),'k','linewidth',1);
else
    plot(wpli.wplispctrm(16,:,41),'k','linewidth',1);
end
axis([1 50 0 0.5]);
ylabel(sprintf('wpli(%s)',wpli_type),'fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25);
ylim([0 1]);
set(gca,'Xtick',10:10:40,'tickdir','out','fontsize',25);

% === EIC ===
subplot 235;
hold on;
imagesc(eic(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[16 16],'w--','linewidth',2);
hold off;
clim([0 max(1, max(max(eic(:,:,41))))]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out'); 
title('EIC','fontsize',25);
colorbar('fontsize', 25);

subplot 236;
plot(eic(16,:,41),'k','linewidth',1);
axis([1 50 0 0.5]);
ylabel('EIC','fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25);
ylim([0 max(1, max(eic(16,:,41)))]);
set(gca,'Xtick',10:10:40,'tickdir','out','fontsize',25);

figure;
subplot 241;
hold on;
imagesc(coh.cohspctrm(:,:,41)-coh1.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[16 16],'w--','linewidth',2);
% plot([16 35],[16 16],'ws','markerfacecolor','w');
hold off;
clim([0 0.4]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out');
colorbar('fontsize', 25);
title('coherence diff','fontsize',25);

% figure;
subplot 245;
hold on;
plot(coh.cohspctrm(16,:,41),'k','linewidth',1);
axis([1 50 0 1]);
plot(coh1.cohspctrm(16,:,41),'r','linewidth',1);
axis([1 50 0 1]);
plot(coh.cohspctrm(16,:,41)-coh1.cohspctrm(16,:,41),'b','linewidth',1);
axis([1 50 0 1]);
hold off;
ylabel('coherence','fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25); 
set(gca,'Xtick',10:10:40,'Ytick',0.2:0.2:0.8,'tickdir','out','fontsize',25);

% figure;
subplot 242;
hold on;
imagesc(icoh.cohspctrm(:,:,41)-icoh1.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[16 16],'w--','linewidth',2);
% plot([16 35],[16 16],'ws','markerfacecolor','w');
hold off;
clim([-0.1 0.1]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out');
colorbar('fontsize', 25);
title('imag(coh) diff','fontsize',25);

% figure;
subplot 246;
hold on;
plot(icoh.cohspctrm(16,:,41),'k','linewidth',1);
axis([1 50 -0.05 0.5]);
plot(icoh1.cohspctrm(16,:,41),'r','linewidth',1);
axis([1 50 -0.05 0.5]);
plot(icoh.cohspctrm(16,:,41)-icoh1.cohspctrm(16,:,41),'b','linewidth',1);
axis([1 50 -0.05 0.5]);
hold off;
ylabel('imag(coh)','fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25);
set(gca,'Xtick',10:10:40,'Ytick',0.1:0.1:0.4,'tickdir','out','fontsize',25);

%% Now create a connected 'data2' using a generative model with cross terms
% between sources 16 and 35, but with an additional source at location 27
% Figure 6C
cfg_sim.noisecov = diag(0.05*ones(cfg_sim.nsignal,1));
cfg_sim.noisecov(16,16) = 1;
cfg_sim.noisecov(35,35) = 1;
cfg_sim.noisecov(27,27) = 1;
cfg_sim.params(16,35,1) = 0.25;
cfg_sim.params(16,35,2) = -0.1; %connect these sources, with a time lag
data2 = ft_apply_montage(ft_connectivitysimulation(cfg_sim), montage);

% Cross-spectral density computation
freq2 = ft_checkdata(ft_freqanalysis(cfg_freq, data2), 'cmbstyle', 'fullfast');

% Coherence calculation
cfg_conn.complex = 'abs';
coh2 = ft_connectivityanalysis(cfg_conn, freq2);
cfg_conn.complex = 'absimag';
icoh2 = ft_connectivityanalysis(cfg_conn, freq2);

% figure;
subplot 243;
hold on;
imagesc(coh.cohspctrm(:,:,41)-coh2.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[11 11],'w--','linewidth',2);
plot([11 25],[11 11],'ws','markerfacecolor','w');
hold off;
clim([-0.15 0.15]);
axis square;
axis tight;
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out');
colorbar('fontsize', 25);
title('coherence diff','fontsize',25);

% figure;
subplot 247;
hold on;
plot(coh.cohspctrm(11,:,41),'k','linewidth',1);
axis([1 50 -0.1 1]);
plot(coh2.cohspctrm(11,:,41),'r','linewidth',1);
axis([1 50 -0.1 1]);
plot(coh.cohspctrm(11,:,41)-coh2.cohspctrm(11,:,41),'b','linewidth',1);
axis([1 50 -0.1 1]);
hold off;
ylabel('coherence','fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25); 
set(gca,'Xtick',10:10:40,'Ytick',0.2:0.2:0.8,'tickdir','out','fontsize',25);

% figure;
subplot 244;
hold on;
imagesc(icoh.cohspctrm(:,:,41)-icoh2.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wx','markerfacecolor','w','LineWidth',2,'MarkerSize',12);
plot([0.5 50.5],[22 22],'w--','linewidth',2);
plot([22 30],[22 22],'ws','markerfacecolor','w');
hold off;
clim([-0.1 0.1]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out');
colorbar('fontsize', 25);
title('imag(coh) diff','fontsize',25);

% figure;
subplot 248;
hold on;
plot(icoh.cohspctrm(22,:,41),'k','linewidth',1);
axis([1 50 -0.05 0.5]);
plot(icoh2.cohspctrm(22,:,41),'r','linewidth',1);
axis([1 50 -0.05 0.5]);
plot(icoh.cohspctrm(22,:,41)-icoh2.cohspctrm(22,:,41),'b','linewidth',1);
axis([1 50 -0.05 0.5]);
hold off;
ylabel('imag(coh)','fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25);
set(gca,'Xtick',10:10:40,'Ytick',0.1:0.1:0.4,'tickdir','out','fontsize',25);

%% Create 'data' and 'data2' using a similar generative model, but with one
% of the originally 'active sources' having a larger power in one of the 'conditions'
% Figure 6D
cfg_sim.noisecov(16,16) = 1;
cfg_sim.noisecov(35,35) = 1;
cfg_sim.noisecov(27,27) = 0.05;
data = ft_apply_montage(ft_connectivitysimulation(cfg_sim), montage);
cfg_sim.noisecov(16,16) = 1;
cfg_sim.noisecov(35,35) = 2; % power increased 2x
data2 = ft_apply_montage(ft_connectivitysimulation(cfg_sim), montage);

% Cross-spectral density computation
freq = ft_checkdata(ft_freqanalysis(cfg_freq, data), 'cmbstyle', 'fullfast');
freq2 = ft_checkdata(ft_freqanalysis(cfg_freq, data2), 'cmbstyle', 'fullfast');

% Coherence calculation cfg_conn.complex = 'abs';
coh = ft_connectivityanalysis(cfg_conn, freq);
coh2 = ft_connectivityanalysis(cfg_conn, freq2);
cfg_conn.complex = 'absimag';
icoh = ft_connectivityanalysis(cfg_conn, freq);
icoh2 = ft_connectivityanalysis(cfg_conn, freq2);

figure;
subplot 221;
hold on;
imagesc(coh2.cohspctrm(:,:,41)-coh.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wo','markerfacecolor','w');
plot([0.5 50.5],[16 16],'w--','linewidth',2);
plot([16 35],[16 16],'ws','markerfacecolor','w');
hold off;
clim([-0.2 0.2]);
axis square;
axis tight
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out');
colorbar('fontsize', 25);
title('coherence diff','fontsize',25);

% figure;
subplot 222;
hold on;
plot(coh2.cohspctrm(16,:,41),'k','linewidth',1);
axis([1 50 -0.1 1]);
plot(coh.cohspctrm(16,:,41),'r','linewidth',1);
axis([1 50 -0.1 1]);
plot(coh2.cohspctrm(16,:,41)-coh.cohspctrm(16,:,41),'b','linewidth',1);
axis([1 50 -0.1 1]);
plot([1 50],[0 0],'k--');
ylabel('coherence','fontsize', 25);
hold off;
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25); 
set(gca,'Xtick',10:10:40,'Ytick',0.2:0.2:0.8,'tickdir','out','fontsize',25);

% figure;
subplot 223;
hold on;
imagesc(icoh2.cohspctrm(:,:,41)-icoh.cohspctrm(:,:,41));
plot([0.5 50.5],[0.5 50.5],'w','linewidth',2);
plot([16 35],[16 35],'wo','markerfacecolor','w');
plot([0.5 50.5],[16 16],'w--','linewidth',2);
plot([16 35],[16 16],'ws','markerfacecolor','w');
hold off;
clim([-0.2 0.2]);
axis square;
axis tight;
set(gca,'fontsize', 25, 'Xtick', 10:10:40, 'Ytick', 10:10:40, 'tickdir', 'out');
colorbar('fontsize', 25);
title('imag(coh) diff','fontsize',25);

% figure;
subplot 224;
hold on;
plot(icoh.cohspctrm(16,:,41),'r','linewidth',1);
axis([1 50 -0.05 0.6]);
plot(icoh2.cohspctrm(16,:,41),'k','linewidth',1);
axis([1 50 -0.05 0.6]);
plot(icoh2.cohspctrm(16,:,41)-icoh.cohspctrm(16,:,41),'b','linewidth',1);
axis([1 50 -0.05 0.6]);
hold off;
ylabel('imag(coh)','fontsize', 25);
xlabel('sensor','fontsize', 25);
set(gca,'fontsize', 25);
set(gca,'Xtick',10:10:40,'Ytick',0.1:0.1:0.4,'tickdir','out','fontsize',25);