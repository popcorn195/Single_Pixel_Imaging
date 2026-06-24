% Q_k,i,j = sum sum [ M_k(x-iΔx, y-jΔy) * O(x,y) ]
% Q[ N*(Nx+1)*(Ny+1) , 1 ]

% object[H_obj x W_obj] : ground truth image 
% patterns : array {N x 1} of [p x p] binary patterns
% Mx, My : effective imaging area dimensions
% Nx, Ny : number of subpixel shifts
% noise_std : standard deviation of Gaussian noise (0 = no noise)

function Q = simulate_bucket_signal( ...
    object,H,Mx,My,Nx,Ny,binFactor,noise_std)

    if nargin < 8
        noise_std = 0;
    end

    Mx_hr = Mx * binFactor;
    My_hr = My * binFactor;

    object = double(object);

    if ndims(object)==3
        object = rgb2gray(uint8(object));
        object = double(object);
    end

    object = imresize(object,[My_hr Mx_hr]);

    object = object - min(object(:));

    if max(object(:))>0
        object = object/max(object(:));
    end

    assert(size(H,2)==numel(object));

    Q = H*object(:);

    if noise_std > 0
        Q = Q + noise_std*max(Q)*randn(size(Q));
    end

end