imFile = '~/Downloads/DCR_A_739_LZW.tif';
imInfo = imfinfo(imFile);

totIm = numel(imInfo);
TiffToMat = matfile('test.mat','Writable',true);

TiffToMat.Y(imInfo(1).Height, imInfo(1).Width, totIm) = uint8(0);
% = 0;
for frame = 1:totIm
    disp(frame)
    TiffToMat.Y(:,:,frame) = imread(imFile, frame);
end

%%
figure,
plot(log2(abs(diffI)))

%%

for frame = 10%5:15
    figure, imshow(imread(imFile, frame));
end