%bmpDir = '/Volumes/MyPassport/Worms/Wormtracker/20141222_test_full/DCR_B_877/';
%tiffName = '/Volumes/MyPassport/Worms/Wormtracker/20141222_test_full/DCR_B_877_crop.tif';
bmpDir = '/Volumes/MyPassport/Worms/Wormtracker/20141222_test_mask/DCR_A_879/';
tiffName = '/Volumes/MyPassport/Worms/Wormtracker/20141222_test_mask/DCR_A_879_crop.tif';

files = dir([bmpDir '*.BMP']);

indexS = zeros(size(files));

for ii = 1:numel(files)
    dum = strsplit(files(ii).name, '_');
    indexS(ii) = str2double(dum{4}(1:end-4));
end



[~,ind] = sort(indexS);

I = rgb2gray(imread([bmpDir files(ind(5)).name]));
[~, rect] = imcrop(I);
%%

fidTiff = Tiff(tiffName, 'w');
for ii = ind(1:200)'
    fidTiff.setTag('Photometric', Tiff.Photometric.MinIsBlack) %gray image zero is interpreted as black
    fidTiff.setTag('ImageLength', round(rect(4)))
    fidTiff.setTag('ImageWidth', round(rect(3)))
    fidTiff.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky)
    fidTiff.setTag('BitsPerSample', 8) %uint8 image
    fidTiff.setTag('Compression', Tiff.Compression.LZW);
    
    I = rgb2gray(imread([bmpDir files(ind(ii)).name]));
    Icrop = imcrop(I, rect);
    fidTiff.write(Icrop);
    fidTiff.writeDirectory()
    disp(ii)
end
fidTiff.close()