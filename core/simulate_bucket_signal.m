% Q_k,i,j = sum sum [ M_k(x-iΔx, y-jΔy) * O(x,y) ]
% Q[ N*(Nx+1)*(Ny+1) , 1 ]

% object[H_obj x W_obj] : ground truth image 
% patterns : array {N x 1} of [p x p] binary patterns
% Mx, My : effective imaging area dimensions
% Nx, Ny : number of subpixel shifts
% noise_std : standard deviation of Gaussian noise (0 = no noise)

function Q = simulate_bucket_signal(object, patterns, Mx, My, Nx, Ny, noise_std)
    if nargin < 7
        noise_std = 0;
    end

    N = length(patterns);

    % force 2D — imread sometimes loads [HxWx1]
    object = double(squeeze(object));

    % force grayscale if RGB was accidentally passed
    if ndims(object) == 3
        object = rgb2gray(object);
        object = double(object);
    end

    % normalise
    object = object / max(object(:));

    expected_H = My * (Ny+1);
    expected_W = Mx * (Nx+1);

    fprintf('Object size after squeeze: %dx%d | Expected: %dx%d\n', ...
            size(object,1), size(object,2), expected_H, expected_W);

    % resize only if needed
    if size(object,1) ~= expected_H || size(object,2) ~= expected_W
        fprintf('Resizing object...\n');
        object = imresize(object, [expected_H, expected_W]);
    end

    total_measurements = N * (Nx+1) * (Ny+1);
    Q = zeros(total_measurements, 1);

    meas_idx = 1;

    for k = 1:N
        base_pattern = double(patterns{k});

        for i = 0:Nx
            for j = 0:Ny
                % shift pattern
                shifted = circshift(base_pattern, [j, i]);

                % crop effective area
                effective = shifted(2:My+1, 2:Mx+1);

                % upsample to subpixel resolution
                subpixel_pattern = double(kron(effective, ones(Ny+1, Nx+1)));

                % explicit size debug print on first iteration only
                if meas_idx == 1
                    fprintf('First iteration sizes:\n');
                    fprintf('  subpixel_pattern: %dx%d\n', ...
                            size(subpixel_pattern,1), size(subpixel_pattern,2));
                    fprintf('  object:           %dx%d\n', ...
                            size(object,1), size(object,2));
                    fprintf('  ndims pattern:    %d\n', ndims(subpixel_pattern));
                    fprintf('  ndims object:     %d\n', ndims(object));
                end

                % compute bucket signal
                Q(meas_idx) = sum(sum(subpixel_pattern .* object));
                meas_idx = meas_idx + 1;
            end
        end
    end

    % add noise
    if noise_std > 0
        Q = Q + noise_std * randn(size(Q));
    end

    fprintf('Bucket signals computed: %d measurements\n', total_measurements);
end