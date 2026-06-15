% computes PSNR and SSIM between reconstructed and ground truth images

% Inputs:
%   img_recon : reconstructed image (normalised 0-1)
%   img_ref : ground truth image  (normalised 0-1)

% Output:
%   metrics : struct with fields psnr_val, ssim_val


function metrics = evaluate_metrics(img_recon, img_ref)

    img_recon = double(squeeze(img_recon));
    img_ref   = double(squeeze(img_ref));
    
    
    if ~isequal(size(img_recon), size(img_ref))
        fprintf('Resizing reconstructed image from [%dx%d] to [%dx%d]\n', ...
            size(img_recon,1), size(img_recon,2), ...
            size(img_ref,1),   size(img_ref,2));
        img_recon = imresize(img_recon, size(img_ref));
    end
    
    
    img_recon = img_recon - min(img_recon(:));
    img_ref   = img_ref   - min(img_ref(:));
    
    if max(img_recon(:)) > 0
        img_recon = img_recon / max(img_recon(:));
    end
    
    if max(img_ref(:)) > 0
        img_ref = img_ref / max(img_ref(:));
    end
    
    
    % PSNR
    metrics.psnr_val = psnr(img_recon, img_ref);
    
    % SSIM
    metrics.ssim_val = ssim(img_recon, img_ref);
    
    
    fprintf('PSNR: %.2f dB\n', metrics.psnr_val);
    fprintf('SSIM: %.4f\n',    metrics.ssim_val);

end