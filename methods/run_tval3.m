%image reconstruction using TVAL3

close all;
clear all;

addpath(genpath(pwd));

num_csmeas=1000;

x = imread('arrow_source.png');

A = readmatrix('phi_for_p_mat_64.txt'); 
A = A(1:num_csmeas, :);

load cs_meas.mat;
y = y(1:num_csmeas,:);

clear opts
opts.mu = 2^8;
opts.beta = 2^5;
opts.tol = 1E-3;
opts.maxit = 300;
opts.TVnorm = 1;
opts.nonneg = false;

t = cputime;
[U, out] = TVAL3(A,y,64,64,opts);
t = cputime - t ;

figure;
subplot(1, 2, 1);  % 1 row, 2 columns, first image
imagesc(x);
title('Original Image');

subplot(1, 2, 2);  % second image
imagesc(U);colormap("gray");
title('Reconstructed Image');
