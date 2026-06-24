% master script: implements SPI with subpixel speckle shift up to O*

% p : base speckle pattern size (16, 32, 64)
% bin_factor : for pixel binning
% Mx : effective imaging area width
% My : effective imaging area height
% Nx : subpixel shifts in x (2, 4, 8)
% Ny : subpixel shifts in y
% N : number of random speckle patterns

% cc[ (p+2) , (p+2) ] : +2 for border (effective area)
% patterns : array {N x 1} of [(p+2) , (p+2)] binary patterns

clear; 
clc; 
close all;

addpath('data/images');

% parameters
p = 16;            
Mx = p;        
My = p;       
Nx = 2;      
Ny = 2; 
bin_factor = 2;

sampling_rate = 0.5;
N = round(sampling_rate * (p)^2);

noise_std = 0.00;      

tic

fprintf('-SPI Subpixel Shift Reconstruction-\n');
fprintf('\nSpeckle size: %dx%d | Shifts: (%d,%d) | Patterns: %d\n', p, p, Nx, Ny, N);


target_H = My * bin_factor;   
target_W = Mx * bin_factor;   

% img
img = imread('data/images/arrow_source.png');

img = double(squeeze(img));
if ndims(img) == 3
    img = rgb2gray(uint8(img));
    img = double(img);
end

img = imresize(img, [target_H, target_W]);
img = img / max(img(:));

fprintf('Object loaded: %dx%d | ndims: %d | class: %s\n', size(img,1), size(img,2), ndims(img), class(img));


% generating speckle patterns
fprintf('\nGenerating %d speckle patterns...\n', N);

patterns = cell(N, 1);

for k = 1:N
    patterns{k} = generate_speckle(p);
end


% H matx
fprintf('\nBuilding H matrix...\n');
H = build_H_matrix(patterns, Mx, My, Nx, Ny, bin_factor);

save('data/patterns/H_matrix.mat', 'H', 'patterns', 'Mx', 'My', 'Nx', 'Ny');
fprintf('H matrix saved.\n');


% bucket signals
fprintf('\nSimulating bucket signals Q...\n');
Q = simulate_bucket_signal(img, H, Mx, My, Nx, Ny, bin_factor, noise_std);

save('data/measurements/Q_vector.mat', 'Q');
fprintf('Q vector saved.\n');


% reconstruct O*
fprintf('\nReconstructing O*...\n');
% [O_star, H_pinv] = subpixel_reconstruct(H, Q, Mx, My, Nx, Ny);
[O_star] = subpixel_reconstruct(H, Q, Mx, My, Nx, Ny, bin_factor);

elapsedTime = toc; 


% evaluate
fprintf('\n-Metrics-\n');

fprintf('Execution time: %.4f seconds\n', elapsedTime);

fprintf('\nWith subpixel shift (O*):\n');

fprintf('\n===== DEBUG =====\n');

fprintf('max abs diff  = %.6f\n', ...
    max(abs(O_star(:)-img(:))));

fprintf('mean abs diff = %.6f\n', ...
    mean(abs(O_star(:)-img(:))));

fprintf('rmse          = %.6f\n', ...
    sqrt(mean((O_star(:)-img(:)).^2)));

fprintf('img range     = [%.6f %.6f]\n', ...
    min(img(:)), max(img(:)));

fprintf('O* range      = [%.6f %.6f]\n', ...
    min(O_star(:)), max(O_star(:)));




fprintf('\n=== SANITY CHECK ===\n');

A = O_star;
B = img;

fprintf('A min/max = %.12f %.12f\n', min(A(:)), max(A(:)));
fprintf('B min/max = %.12f %.12f\n', min(B(:)), max(B(:)));

D = A - B;

fprintf('max abs diff = %.12f\n', max(abs(D(:))));
fprintf('mean abs diff = %.12f\n', mean(abs(D(:))));

mse = mean(D(:).^2);
rmse = sqrt(mse);

fprintf('MSE  = %.12f\n', mse);
fprintf('RMSE = %.12f\n', rmse);

fprintf('norm(A-B) = %.12f\n', norm(D(:)));





fprintf('\nWith subpixel shift (O*):\n');

fprintf('Direct PSNR = %.4f\n', psnr(O_star,img,1));
fprintf('Direct SSIM = %.4f\n', ssim(O_star,img));

metrics_star = evaluate_metrics(O_star,img);





figure('Name', 'SPI Subpixel Reconstruction', 'Position', [100 100 1200 400]);

subplot(1,2,1);
imshow(img, []);
title(sprintf('Ground Truth\n%dx%d', size(img,1), size(img,2)));

subplot(1,2,2);
imshow(O_star, []);
title(sprintf('With Subpixel Shift O*\nSSIM: %.4f | PSNR: %.2fdB', ...
      metrics_star.ssim_val, metrics_star.psnr_val));

sgtitle(sprintf('SPI Reconstruction | p=%d | Shifts=(%d,%d) | N=%d patterns | Time=%.2f', ...
        p, Nx, Ny, N,elapsedTime));


fprintf('Relative reconstruction error = %.12f\n', ...
    norm(O_star(:)-img(:))/norm(img(:)));



%saveas(gcf, 'results/figures/O_star_comparison.png');
saveas(gcf, sprintf('results/figures/O_star_comparison_p%d_N%d_Nx%d_Ny%d.png', ...
    p, N, Nx, Ny));
fprintf('\nFigure saved to results/figures/\n');

%save('results/metrics/metrics.mat', 'metrics_star');
save(sprintf('results/metrics/metrics_p%d_N%d_Nx%d_Ny%d.mat', ...
    p, N, Nx, Ny), 'metrics_star');
fprintf('Metrics saved.\n');


save(sprintf('results/figures/O_star_p%d.mat', p), 'O_star');

fprintf('\nDone\n');



