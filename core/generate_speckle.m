% generate random binary speckle pattern 
% cc[pXp] : coded mask
% p : base speckle pattern size (16, 32, 64)

function cc= generate_speckle(p)
    
    cc=(sign(randn(p,p)) + ones(p,p))/2;

end