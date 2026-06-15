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
bin_factor = 4;      
Mx = p;        
My = p;       
Nx = 2;      
Ny = 2;        

sampling_rate = 0.5;
N = round(sampling_rate * (p+2)^2);

noise_std = 0.0;      

tic

fprintf('-SPI Subpixel Shift Reconstruction-\n');
fprintf('\nSpeckle size: %dx%d | Shifts: (%d,%d) | Patterns: %d\n', p, p, Nx, Ny, N);


% img
img = imread('data/images/arrow_source.png');

img = double(squeeze(img));
if ndims(img) == 3
    img = rgb2gray(uint8(img));
    img = double(img);
end

img = img / max(img(:));

target_H = My * (Ny+1);
target_W = Mx * (Nx+1);
img = imresize(img, [target_H, target_W]);
img = img / max(img(:));

fprintf('Object loaded: %dx%d | ndims: %d | class: %s\n', size(img,1), size(img,2), ndims(img), class(img));


% generating speckle patterns
fprintf('\nGenerating %d speckle patterns...\n', N);
patterns = cell(N, 1);

for k = 1:N
    cc = generate_speckle(p+2);                                  
    patterns{k} = double(cc);

    % for hardware integration:
    % cc_binned = pixel_bin(cc, bin_factor);
    % patterns{k} = double(cc_binned);
end


% H matx
fprintf('\nBuilding H matrix...\n');
H = build_H_matrix(patterns, Mx, My, Nx, Ny);

save('data/patterns/H_matrix.mat', 'H', 'patterns', 'Mx', 'My', 'Nx', 'Ny');
fprintf('H matrix saved.\n');


% bucket signals
fprintf('\nSimulating bucket signals Q...\n');
Q = simulate_bucket_signal(img, patterns, Mx, My, Nx, Ny, noise_std);

save('data/measurements/Q_vector.mat', 'Q');
fprintf('Q vector saved.\n');


% reconstruct O*
fprintf('\nReconstructing O*...\n');
% [O_star, H_pinv] = subpixel_reconstruct(H, Q, Mx, My, Nx, Ny);
[O_star] = subpixel_reconstruct(H, Q, Mx, My, Nx, Ny);

elapsedTime = toc; 


% evaluate
fprintf('\n-Metrics-\n');

fprintf('Execution time: %.4f seconds\n', elapsedTime);

fprintf('\nWith subpixel shift (O*):\n');
metrics_star = evaluate_metrics(O_star, img);

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




%saveas(gcf, 'results/figures/O_star_comparison.png');
saveas(gcf, sprintf('results/figures/O_star_comparison_p%d_N%d_Nx%d_Ny%d.png', ...
    p, N, Nx, Ny));
fprintf('\nFigure saved to results/figures/\n');

%save('results/metrics/metrics.mat', 'metrics_star');
save(sprintf('results/metrics/metrics_p%d_N%d_Nx%d_Ny%d.mat', ...
    p, N, Nx, Ny), 'metrics_star');
fprintf('Metrics saved.\n');
fprintf('\nDone\n');

