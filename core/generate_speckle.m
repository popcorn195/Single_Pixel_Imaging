% generate random binary speckle pattern 
% cc[pXp] : coded mask

function cc= generate_speckle(p)
    
    cc=(sign(randn(p,p)) + ones(p,p))/2;

end