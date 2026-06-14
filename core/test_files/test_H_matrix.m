% master script: implements SPI with subpixel speckle shift up to O*

% p : base speckle pattern size (16, 32, 64)
% Mx : effective imaging area width
% My : effective imaging area height
% Nx : subpixel shifts in x (2, 4, 8)
% Ny : subpixel shifts in y
% N : number of random speckle patterns

% cc[ (p+2) , (p+2) ] : +2 for border (effective area)
% patterns : array {N x 1} of [(p+2) , (p+2)] binary patterns

clear; clc; close all;
addpath('core');

p  = 2;   
Nx = 1;   
Ny = 1;  
N  = 1;   

pat = [0 0 0 0;
       0 1 0 0;
       0 0 1 0;
       0 0 0 0];

patterns    = cell(1,1);
patterns{1} = double(pat);

fprintf('Base pattern:\n'); disp(pat);
fprintf('Effective area:\n'); disp(pat(2:p+1, 2:p+1));


total_shifts = (Nx+1) * (Ny+1);   % = 4
% grid: 4 rows (one per stage), total_shifts cols (one per shift)
% total subplots = 4 * 4 = 16  

figure('Name','Subpixel Shifts','Position',[100 100 1000 700]);

col = 1;   

for i = 0:Nx
    for j = 0:Ny

        shifted   = circshift(pat, [j, i]);

        effective = shifted(2:p+1, 2:p+1);

        subpixel  = kron(effective, ones(Ny+1, Nx+1));

        h_row_2d  = reshape(subpixel(:)', size(subpixel));


        fprintf('\n--- shift(i=%d j=%d) ---\n', i, j);
        fprintf('shifted:\n'); disp(shifted);
        fprintf('effective:\n'); disp(effective);
        fprintf('subpixel:\n'); disp(subpixel);
        fprintf('H row:\n'); disp(subpixel(:)');

        % shifted pattern
        subplot(4, total_shifts, col);
        imagesc(shifted); colormap gray; axis image off;
        hold on;
        rectangle('Position',[1.5 1.5 p p],'EdgeColor','r','LineWidth',2);
        title(sprintf('i=%d j=%d\nshifted',i,j),'FontSize',8);

        %effective area
        subplot(4, total_shifts, col + total_shifts);
        imagesc(effective); colormap gray; axis image off;
        title(sprintf('effective\n%dx%d',p,p),'FontSize',8);

        %subpixel
        subplot(4, total_shifts, col + 2*total_shifts);
        imagesc(subpixel); colormap gray; axis image off;
        title(sprintf('subpixel\n%dx%d',size(subpixel,1),size(subpixel,2)),'FontSize',8);

        %H row reshaped
        subplot(4, total_shifts, col + 3*total_shifts);
        imagesc(h_row_2d); colormap gray; axis image off;
        title(sprintf('H row %d\n[1x%d]',col,numel(subpixel)),'FontSize',8);

        col = col + 1;
    end
end


annotation('textbox',[0.01 0.75 0.07 0.05],'String','Shifted', ...
           'EdgeColor','none','FontSize',9,'FontWeight','bold');
annotation('textbox',[0.01 0.52 0.07 0.05],'String','Effective', ...
           'EdgeColor','none','FontSize',9,'FontWeight','bold');
annotation('textbox',[0.01 0.29 0.07 0.05],'String','Subpixel', ...
           'EdgeColor','none','FontSize',9,'FontWeight','bold');
annotation('textbox',[0.01 0.06 0.07 0.05],'String','H row', ...
           'EdgeColor','none','FontSize',9,'FontWeight','bold');

sgtitle(sprintf('p=%d Nx=%d Ny=%d | %d shifts | red=effective area', ...
        p, Nx, Ny, total_shifts));
saveas(gcf,'results/figures/test_H_shifts.png');
fprintf('\nFigure saved.\n');
