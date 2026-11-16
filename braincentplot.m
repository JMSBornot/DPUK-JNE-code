function hlink = braincentplot(surf, cent, X, dim, freqband_labels, transp, fcbar)

Nf = length(freqband_labels);
xm = reshape(mean(X,dim),[],Nf);
xs = reshape(std(X,0,dim),[],Nf);
xb = xs/sqrt(size(X,dim)); % error bar
Nd = size(xm,1);

valmax = 1.1*max(max(abs(xm) + abs(xb)));
figure;
for i = 1:Nf
    subplot(Nf,1,i);
    bar(1:Nd, xm(:,i));
    hold on;
    herr = errorbar(1:Nd, xm(:,i), xb(:,i), xb(:,i));
    herr.LineStyle = 'None';
    herr.Color=[0 0 0];
    hold off;
    ylabel(freqband_labels{i});
    set(gca,'fontsize',14,'ylim',valmax*[-1 1]);
end

zscore = xm./xb;
zscore(isnan(zscore)) = 0;
cutoff = norminv(1 - 0.05/2/Nf/Nd);
zscore(abs(zscore)<cutoff) = 0;

sz = abs(zscore);
cmax = max(max(sz));
sz = 200*sz/cmax;

figure;
hax = zeros(1,Nf);
for i = 1:Nf
    hax(i) = subplot(2,3,i);
    patch('faces',surf.faces,'vertices',surf.vertices,'FaceColor',0.9*ones(1,3),'EdgeColor','none','FaceAlpha',transp);
%     lightangle(gca,-45,30); lighting gouraud, lightangle(gca,45,30); lighting gouraud, rotate3d on; axis image;
    lightangle(gca,-90,15); lighting gouraud, lightangle(gca,90,15); lighting gouraud, rotate3d on; axis image;
    hold on;
    
    flag = (sz(:,i) > 0);
    scatter3(cent(flag,1), cent(flag,2), cent(flag,3), sz(flag,i), zscore(flag,i), 'filled');
    caxis(cmax*[-1 1]);
    if fcbar
        colorbar;
    end

    hold off;

    box on;
    ylabel(freqband_labels{i});
    set(gca,'fontsize',14);
end
hlink = linkprop(hax,{'CameraPosition','CameraUpVector'});
rotate3d on;