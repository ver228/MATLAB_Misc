function outputvalues = asintransform(inputvalues, varargin)

    n = NaN;
    if nargin >= 2
        n = varargin{1};
    end

    where0 = inputvalues == 0;
    where1 = inputvalues == 1;
    
    if (any(where0) || any(where1)) && isnan(n)
        error('Unknown n-number when trying to perform arcsine transformation on proportion values containing 0s or 1s');
    else
        inputvalues(where0) = 1/(4*n); %convention
        inputvalues(where1) = 1-1/(4*n); %convention
    end
    
    outputvalues = asin(realsqrt(inputvalues));

end