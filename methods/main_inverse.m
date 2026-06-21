% master script to run inverse problem reconstruction

clear; clc; close all;
addpath(genpath(pwd));

img_path = 'data/images/arrow_source.png';
phi_path = 'data/patterns/phi_for_p_mat_64.txt';
meas_path = 'data/measurements/cs_meas.mat';
num_meas = 1000;

[U, metrics] = run_inverse(img_path, phi_path, meas_path, num_meas);

fprintf('\n=== Inverse Problem Results ===\n');
fprintf('SSIM: %.4f\n', metrics.ssim_val);
fprintf('PSNR: %.2f dB\n', metrics.psnr_val);