% Inputs:
%   img_path : path to ground truth image
%   phi_path : path to measurement matrix phi 
%   meas_path : path to measurements y
%   num_meas : number of CS measurements to use

function [U, metrics] = run_tval3(img_path, phi_path, meas_path, num_meas)

    if nargin < 4
        num_meas = 1000;
    end
    

    x = imread(img_path);
    x = double(rgb2gray(x));    
    x = x / max(x(:));          
    
    A = dlmread(phi_path);
    A = A(1:num_meas, :);
    
    load(meas_path, 'y');
    y = y(1:num_meas, :);
    
    fprintf('Image size:     %dx%d\n', size(x,1), size(x,2));
    fprintf('A size:         %dx%d\n', size(A,1), size(A,2));
    fprintf('y length:       %d\n',    length(y));
    

    opts.mu      = 2^8;
    opts.beta    = 2^5;
    opts.tol     = 1e-3;
    opts.maxit   = 300;
    opts.TVnorm  = 1;
    opts.nonneg  = false;
    

    fprintf('\nRunning TVAL3...\n');

    tic;
        [U, ~] = TVAL3(A, y, 64, 64, opts);
        fprintf('TVAL3 done in %.2f seconds\n', toc);
    
    
    U = double(U);
    U = U - min(U(:));
    U = U / max(U(:));
    

    x_resized = imresize(x, size(U));
    metrics   = evaluate_metrics(U, x_resized);
    

    figure('Position', [100 100 800 400]);
    
    subplot(1,2,1);
    imagesc(x); colormap gray; axis image off;
    title('Original Image');
    
    subplot(1,2,2);
    imagesc(U); colormap gray; axis image off;
    title(sprintf('TVAL3 Reconstruction\nSSIM: %.4f | PSNR: %.2fdB', ...
          metrics.ssim_val, metrics.psnr_val));
    
    sgtitle(sprintf('TVAL3 | measurements=%d', num_meas));
    
    saveas(gcf, sprintf('results/figures/tval3_N%d.png', num_meas));
    fprintf('Figure saved.\n');

end