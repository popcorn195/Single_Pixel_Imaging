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

% [My*(Ny+1) , Mx*(Nx+1)] = [4x4]
object = [0.8 0.2 0.1 0.9;
          0.3 0.7 0.4 0.2;
          0.6 0.1 0.8 0.3;
          0.2 0.5 0.3 0.7];

patterns = cell(1,1);
patterns{1} = double(pat);

fprintf('Base pattern:\n');  disp(pat);
fprintf('Object (4x4):\n'); disp(object);


total_shifts = (Nx+1)*(Ny+1);   % = 4
Q_manual = zeros(total_shifts, 1);

figure('Name','Bucket Signal Steps','Position',[100 100 1100 700]);

col = 1;
for i = 0:Nx
    for j = 0:Ny

        shifted = circshift(pat, [j, i]);
        effective = shifted(2:p+1, 2:p+1);
        subpixel = double(kron(effective, ones(Ny+1, Nx+1)));

        object_norm = object / max(object(:));
        product = subpixel .* object_norm;
        Q_manual(col) = sum(product(:));

        fprintf('\n--- shift(i=%d j=%d) ---\n', i, j);
        fprintf('subpixel pattern:\n'); disp(subpixel);
        fprintf('object:\n'); disp(object);
        fprintf('product:\n'); disp(product);
        fprintf('Q(%d) = sum = %.4f\n', col, Q_manual(col));

        % subpixel pattern
        subplot(3, total_shifts, col);
        imagesc(subpixel); colormap gray; axis image off;
        title(sprintf('i=%d j=%d\npattern',i,j),'FontSize',8);

        % object
        subplot(3, total_shifts, col + total_shifts);
        imagesc(object_norm); colormap gray; axis image off;
        title(sprintf('object\n%dx%d',size(object,1),size(object,2)),'FontSize',8);
        colorbar;

        % product
        subplot(3, total_shifts, col + 2*total_shifts);
        imagesc(product); colormap gray; axis image off;
        title(sprintf('product\nQ=%.3f',Q_manual(col)),'FontSize',8);
        colorbar;

        col = col + 1;
    end
end


annotation('textbox',[0.01 0.72 0.07 0.05],'String','Pattern', ...
           'EdgeColor','none','FontSize',9,'FontWeight','bold');
annotation('textbox',[0.01 0.42 0.07 0.05],'String','Object', ...
           'EdgeColor','none','FontSize',9,'FontWeight','bold');
annotation('textbox',[0.01 0.12 0.07 0.05],'String','Product', ...
           'EdgeColor','none','FontSize',9,'FontWeight','bold');

sgtitle(sprintf('Bucket Signal Q | p=%d Nx=%d Ny=%d | Q = sum(pattern x object)', ...
        p, Nx, Ny));
saveas(gcf,'results/figures/test_bucket_signal.png');
fprintf('\nFigure saved.\n');


fprintf('\n=== Comparing manual vs simulate_bucket_signal ===\n');
Q_fn = simulate_bucket_signal(object, patterns, p, p, Nx, Ny, 0);

fprintf('\nManual Q:    '); fprintf('%.4f  ', Q_manual); fprintf('\n');
fprintf('Function Q:  '); fprintf('%.4f  ', Q_fn);     fprintf('\n');


checks = {
    'SIZE  ', isequal(size(Q_fn), size(Q_manual));
    'VALUES', max(abs(Q_fn - Q_manual)) < 1e-10;
    'LENGTH', length(Q_fn) == N*(Nx+1)*(Ny+1);
    'NONNEG', all(Q_fn >= 0);
};

fprintf('\n--- Results ---\n');
for k = 1:size(checks,1)
    if checks{k,2}
        fprintf('%s: PASS ✓\n', checks{k,1});
    else
        fprintf('%s: FAIL ✗\n', checks{k,1});
    end
end