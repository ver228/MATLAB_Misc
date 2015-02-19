filename = '/Users/ver228/Documents/MATLAB/testHDF5/DCR_A_739.tif';
info = imfinfo(filename);
I = zeros(info(1).Width, info(1).Height, numel(info), 'uint8');
for ii = 1:numel(info)
    I(:,:,ii) = imread(filename, ii);
end
%%
