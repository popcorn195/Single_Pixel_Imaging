% raw reconstruction
% O* = psuedo-inv(H) * Q

% H[ M , N ]
% Q[ M , 1 ]

function O_star = subpixel_reconstruct(H,Q,Mx,My,Nx,Ny,binFactor)

    recon_H = My * binFactor;
    recon_W = Mx * binFactor;

    O_vec = lsqminnorm(H,Q);

    O_star = reshape(O_vec,[recon_H recon_W]);

    O_star = O_star - min(O_star(:));

    if max(O_star(:)) > 0
        O_star = O_star/max(O_star(:));
    end

end