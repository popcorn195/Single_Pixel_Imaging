%generate_speckle.m->pixel_bin.m->

close all; 

addpath(genpath(pwd));

% DMD size
M = 1024;
N = 768;

% parameters
p = 64;       
bin_factor = 4;

% generate speckle and bin it 
cc = generate_speckle(p);
c  = pixel_bin(cc, bin_factor);

q = p * bin_factor;

% embed in DMD frame 
A = zeros(M, N);
row_start = floor(M/2 - q/2 + 1);
row_end   = floor(M - M/2 + q/2);
col_start = floor(N/2 - q/2 + 1);
col_end   = floor(N - N/2 + q/2);
A(row_start:row_end, col_start:col_end) = c;

figure, imshow(A, []);
title(sprintf('DMD frame [%dx%d] with binned pattern [%dx%d] centered', M, N, q, q));