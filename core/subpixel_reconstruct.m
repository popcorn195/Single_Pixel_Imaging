% raw reconstruction
% O* = psuedo-inv(H) * Q

% H[ M , N ]
% Q[ M , 1 ]

function [O_star,H_pinv] = subpixel_reconstruct(H,Q,Mx,My,Nx,Ny)
    
    H_pinv=pinv(H);
    O_vec = H_pinv * Q;

    recon_H= My*(Ny+1);
    recon_W= Mx*(Nx+1);
    O_star= reshape(O_vec, [recon_H , recon_W] );

    O_star = O_star - min(O_star(:));
    O_star = O_star / max(O_star(:));

    fprintf('O* reconstruction complete: %dx%d image\n', recon_H, recon_W);
    
end