function metrics = evaluate_metrics(img_recon, img_ref)

    img_recon = double(img_recon);
    img_ref   = double(img_ref);

    % Resize if needed
    if ~isequal(size(img_recon), size(img_ref))
        img_recon = imresize(img_recon, size(img_ref));
    end

    % Clamp to [0,1]
    img_recon = max(min(img_recon,1),0);
    img_ref   = max(min(img_ref,1),0);

    % Compute metrics directly
    metrics.psnr_val = psnr(img_recon, img_ref, 1);
    metrics.ssim_val = ssim(img_recon, img_ref);

    % Additional diagnostics
    mse_val = mean((img_recon(:)-img_ref(:)).^2);

    fprintf('MSE  : %.8f\n', mse_val);
    fprintf('PSNR : %.4f dB\n', metrics.psnr_val);
    fprintf('SSIM : %.4f\n', metrics.ssim_val);

end