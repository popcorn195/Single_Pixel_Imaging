% main_compare.m
% Master script: implements SPI with subpixel speckle shift up to O*
% Based on: Liu et al., IEEE Photonics Technology Letters, 2026

clear; clc; close all;
addpath('core', 'utils', 'data/images');

%% ── PARAMETERS ──────────────────────────────────────────────
p          = 16;       % base speckle pattern size (paper uses 16,32,64)
bin_factor = 4;        % pixel binning factor
Mx         = p;        % effective imaging area width
My         = p;        % effective imaging area height
Nx         = 2;        % subpixel shifts in x (paper: 2,4,8)
Ny         = 2;        % subpixel shifts in y
N          = 100;      % number of random speckle patterns
noise_std  = 0.0;      % noise level (0 = simulation, no noise)

fprintf('=== SPI Subpixel Shift Reconstruction ===\n');
fprintf('Speckle size: %dx%d | Shifts: (%d,%d) | Patterns: %d\n', ...
        p, p, Nx, Ny, N);

%% ── LOAD OBJECT ─────────────────────────────────────────────
img = imread('data/images/arrow_source.png');

% force to 2D grayscale double
img = double(squeeze(img));
if ndims(img) == 3
    img = rgb2gray(uint8(img));
    img = double(img);
end

% normalise
img = img / max(img(:));

% resize to subpixel resolution
target_H = My * (Ny+1);
target_W = Mx * (Nx+1);
img = imresize(img, [target_H, target_W]);
img = img / max(img(:));

fprintf('Object loaded: %dx%d | ndims: %d | class: %s\n', ...
        size(img,1), size(img,2), ndims(img), class(img));

%% ── GENERATE SPECKLE PATTERNS ───────────────────────────────
fprintf('\nGenerating %d speckle patterns...\n', N);
patterns = cell(N, 1);

for k = 1:N
    cc = generate_speckle(p+2);       % generate (p+2)x(p+2) pattern
                                       % +2 for border (effective area)
    patterns{k} = double(cc);
end

%% ── BUILD H MATRIX ──────────────────────────────────────────
fprintf('\nBuilding H matrix...\n');
H = build_H_matrix(patterns, Mx, My, Nx, Ny);

% save H for reuse
save('data/patterns/H_matrix.mat', 'H', 'patterns', 'Mx', 'My', 'Nx', 'Ny');
fprintf('H matrix saved.\n');

%% ── SIMULATE BUCKET SIGNALS ─────────────────────────────────
fprintf('\nSimulating bucket signals Q...\n');
Q = simulate_bucket_signal(img, patterns, Mx, My, Nx, Ny, noise_std);

% save Q
save('data/measurements/Q_vector.mat', 'Q');
fprintf('Q vector saved.\n');

%% ── RECONSTRUCT O* ──────────────────────────────────────────
fprintf('\nReconstructing O*...\n');
[O_star, H_pinv] = subpixel_reconstruct(H, Q, Mx, My, Nx, Ny);

%% ── EVALUATE ────────────────────────────────────────────────
fprintf('\n=== Metrics ===\n');

% no shift baseline (single pattern, no subpixel)
% just first pattern, no shift for comparison
H_base   = H(1:N, 1:Mx*My);           % first N rows, base resolution
Q_base   = Q(1:N);
O_base   = reshape(pinv(H_base)*Q_base, [My, Mx]);
O_base   = O_base - min(O_base(:));
O_base   = O_base / max(O_base(:));
img_base = imresize(img, [My, Mx]);

fprintf('Without subpixel shift:\n');
metrics_base = evaluate_metrics(O_base, img_base);

fprintf('\nWith subpixel shift (O*):\n');
metrics_star = evaluate_metrics(O_star, img);

%% ── DISPLAY RESULTS ─────────────────────────────────────────
figure('Name', 'SPI Subpixel Reconstruction', 'Position', [100 100 1200 400]);

subplot(1,3,1);
imshow(img, []);
title(sprintf('Ground Truth\n%dx%d', size(img,1), size(img,2)));

subplot(1,3,2);
imshow(O_base, []);
title(sprintf('Without Shift\nSSIM: %.4f | PSNR: %.2fdB', ...
      metrics_base.ssim_val, metrics_base.psnr_val));

subplot(1,3,3);
imshow(O_star, []);
title(sprintf('With Subpixel Shift O*\nSSIM: %.4f | PSNR: %.2fdB', ...
      metrics_star.ssim_val, metrics_star.psnr_val));

sgtitle(sprintf('SPI Reconstruction | p=%d | Shifts=(%d,%d) | N=%d patterns', ...
        p, Nx, Ny, N));

% save figure
saveas(gcf, 'results/figures/O_star_comparison.png');
fprintf('\nFigure saved to results/figures/\n');

%% ── SAVE METRICS ────────────────────────────────────────────
save('results/metrics/metrics.mat', 'metrics_base', 'metrics_star');
fprintf('Metrics saved.\n');
fprintf('\n=== Done ===\n');

