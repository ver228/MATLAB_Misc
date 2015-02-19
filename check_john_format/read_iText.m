fname = '/Users/ajaver/Downloads/DCR_B_877_itex/DCR_B_877_8180.iTXT';

A = dlmread(fname, '\t', 1,0);
I = full(sparse(A(:,1)+1,A(:,2)+1,A(:,3)));
imshow(I,[])