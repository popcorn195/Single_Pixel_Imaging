%4x4 pixel binning

% bin_factor=4 (say)
% cc[pXp] : binary speckle pattern (coded mask)
% c[qXq] : binned coded mask

function c= pixel_bin(cc,bin_factor)
    
    p=size(cc,1);
    q=p*bin_factor;

    c=zeros([q,q]);
    
    for i=1:p
        for j=1:p
            if(cc(i,j)==1)
                %y=i*4-3;
                %for x=(j*4-3):(j*4)
                %    c(y,x)=1;
                %    c(y+1,x)=1;
                %    c(y+2,x)=1;
                %    c(y+3,x)=1;
                %end

                row_start= (i-1)*bin_factor+1;
                row_end= i*bin_factor;
                col_start = (j-1)*bin_factor+1;
                col_end = j * bin_factor;
                c(row_start:row_end, col_start:col_end) = 1;

            end
        end
    end
    
end

