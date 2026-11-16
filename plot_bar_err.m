function plot_bar_err(xm, xe)
hb = bar(xm);
cent = hb.XData + hb.XOffset;
hold on;
errorbar(cent, xm, xe, ...
    'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1);
hold off;