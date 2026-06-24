% H[ N(Nx+1)(Ny+1) , Mx*My(Nx+1)(Ny+1) ] : measurement matx
% from subpixel shifted speckle patterns (Mk)

% N : number of speckle patterns
% Nx,Ny : max shift values (horizontal & vertical)
% patterns[NX1] : N speckle pattern array, each pattern(CM) is [pXp]

% (Nx+1),(Ny+1) : number of shifts
% Mx,My : effective imaging area size

function H = build_H_matrix(patterns, Mx, My, Nx, Ny, binFactor)

    N = length(patterns);

    Mx_hr = Mx * binFactor;
    My_hr = My * binFactor;

    total_measurements = N * (Nx+1) * (Ny+1);
    total_pixels       = Mx_hr * My_hr;

    H = zeros(total_measurements,total_pixels);
    %H = sparse(total_measurements,total_pixels);

    row_idx = 1;

    for k = 1:N

        base_pattern = double(patterns{k});

        binned = pixel_bin(base_pattern,binFactor);

        for i = 0:Nx
            for j = 0:Ny

                dx = round(i * binFactor / Nx);
                dy = round(j * binFactor / Ny);

                shifted = zeros(size(binned));

                shifted(1+dy:end,1+dx:end) = ...
                    binned(1:end-dy,1:end-dx);

                row_start = floor(size(shifted,1)/2 - My_hr/2) + 1;
                col_start = floor(size(shifted,2)/2 - Mx_hr/2) + 1;

                effective = shifted( ...
                    row_start:row_start+My_hr-1,...
                    col_start:col_start+Mx_hr-1);

                H(row_idx,:) = effective(:)';
                %H(row_idx,:) = sparse(effective(:)');

                row_idx = row_idx + 1;

            end
        end
    end

    fprintf('H matrix built: %d x %d\n', ...
        size(H,1),size(H,2));

    fprintf('Rank(H) = %d\n',rank(H));

end