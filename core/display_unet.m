% loading O_hat back
data  = load(sprintf('unet/outputs/O_hat_p%d.mat', p));
O_hat = data.O_hat;


data2 = load(sprintf('results/figures/O_star_p%d.mat', p));
O_star = data2.O_star;

img = imread('data/images/arrow_source.png');
if ndims(img) == 3
    img = rgb2gray(img);
end

img = double(img);
img = imresize(img, size(O_hat));

% Normalize
img = img - min(img(:));
img = img / max(img(:));

O_hat = O_hat - min(O_hat(:));
O_hat = O_hat / max(O_hat(:));

O_star = O_star - min(O_star(:));
O_star = O_star / max(O_star(:));



fprintf('\n=== U-Net Output Metrics ===\n');
metrics_unet = evaluate_metrics(O_hat, img);

fprintf('\n=== Raw O* Metrics ===\n');
metrics_star = evaluate_metrics(O_star, img);

figure('Position',[100 100 1400 450]);

subplot(1,3,1);
imagesc(img);
colormap gray;
axis image off;
title('Ground Truth');

subplot(1,3,2);
imagesc(O_star);
colormap gray;
axis image off;
title(sprintf('O*\nSSIM=%.4f',metrics_star.ssim_val));

subplot(1,3,3);
imagesc(O_hat);
colormap gray;
axis image off;
title(sprintf('O-hat (U-Net)\nSSIM=%.4f',metrics_unet.ssim_val));

sgtitle(sprintf('SPI Reconstruction Comparison (p=%d)',p));