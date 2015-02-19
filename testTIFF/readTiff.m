imFile = '~/Downloads/DCR_A_739_LZW.tif';
imInfo = imfinfo(imFile);

totIm = numel(imInfo);
meanI = zeros(1,totIm);
stdI = zeros(1,totIm);
diffI = zeros(1,totIm-1);
Aprev = [];
for frame = 1:totIm
    disp(frame)
    A = double(imread(imFile, frame));
    meanI(frame) = mean(A(:));
    stdI(frame) = std(A(:));
    
    if ~isempty(Aprev)
        diffI(frame-1) = mean(A(:)-Aprev(:));
    end
    Aprev = A;
end

%%
figure,
plot(log2(abs(diffI)))

%%

for frame = 10%5:15
    figure, imshow(imread(imFile, frame));
end