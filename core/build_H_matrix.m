% H[ N(Nx+1)(Ny+1) , Mx*My(Nx+1)(Ny+1) ] : measurement matx
% from subpixel shifted speckle patterns (Mk)

% N : number of speckle patterns
% Nx,Ny : max shift values (horizontal & vertical)
% patterns[NX1] : N speckle pattern array, each pattern(CM) is [pXp]

% (Nx+1),(Ny+1) : number of shifts
% Mx,My : effective imaging area size

function H = build_H_matrix(patterns, Mx, My, Nx, Ny)
    N = length(patterns);

    total_measurements = N * (Nx+1) * (Ny+1);
    total_pixels       = Mx * My * (Nx+1) * (Ny+1);

    H = zeros(total_measurements, total_pixels);

    row_idx = 1;

    for k = 1:N
        base_pattern = double(patterns{k});  % [p+2 x p+2]

        for i = 0:Nx
            for j = 0:Ny
                shifted = circshift(base_pattern, [j, i]);

                % crop: [My x Mx]
                effective = shifted(2:My+1, 2:Mx+1);

                % upsample: [My*(Ny+1) x Mx*(Nx+1)]
                subpixel_pattern = kron(effective, ones(Ny+1, Nx+1));  
               
                H(row_idx, :) = subpixel_pattern(:)';

                row_idx = row_idx + 1;
            end
        end
    end

    fprintf('H matrix built: %d x %d\n', size(H,1), size(H,2));
end