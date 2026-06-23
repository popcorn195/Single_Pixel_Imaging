% loading O_hat back
data  = load(sprintf('unet/outputs/O_hat_p%d.mat', p));
O_hat = data.O_hat;

fprintf('\n=== U-Net Output Metrics ===\n');
metrics_unet = evaluate_metrics(O_hat, img);

figure;
subplot(1,3,1); imagesc(img);    colormap gray; axis image off; title('Ground Truth');
subplot(1,3,2); imagesc(O_star); colormap gray; axis image off; title('O* pseudo-inv');
subplot(1,3,3); imagesc(O_hat);  colormap gray; axis image off;
title(sprintf('O-hat U-Net\nSSIM=%.4f', metrics_unet.ssim_val));