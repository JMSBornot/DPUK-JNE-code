function hlink = brainplot(surf, X, dim, freqband_labels, fcbar)

Nf = length(freqband_labels);
xm = reshape(mean(X,dim),[],Nf);
xs = reshape(std(X,0,dim),[],Nf);
xb = xs/sqrt(size(X,dim)); % error bar
% Nd = size(xm,1);

zscore = xm./xb;
zscore(isnan(zscore)) = 0;
% cutoff = norminv(1 - 0.05/2/Nf/Nd);
% zscore(abs(zscore)<cutoff) = 0;
cmax = max(max(abs(zscore)))/2;

figure;
hax = zeros(1,Nf);
for i = 1:Nf
    hax(i) = subplot(2,3,i);
    patch('faces',surf.faces,'vertices',surf.vertices,'FaceColor',0.95*ones(1,3),'EdgeColor','none');
    lightangle(gca,-90,15); lighting gouraud, lightangle(gca,90,15); lighting gouraud, rotate3d on; axis image;
    
    hold on;
    patch('faces', surf.faces, 'vertices', surf.vertices, 'EdgeColor', 'none', ...
        'FaceVertexCData', zscore(:,i), 'FaceVertexAlphaData', abs(zscore(:,i)), ...
        'FaceColor', 'interp', 'FaceAlpha', 'interp', 'AlphaDataMapping', 'scaled');
    colormap jet;

    clim(cmax*[-1 1]);
    if fcbar
        colorbar;
    end
    hold off;

    % box on;
    axis off;
    % ylabel(freqband_labels{i});
    % set(gca,'fontsize',14);
end
hlink = linkprop(hax,{'CameraPosition','CameraUpVector'});
rotate3d on;