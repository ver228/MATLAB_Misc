bmpDir = '/Users/ver228/Downloads/DCR_F_574/';
bmpList = dir([bmpDir '*.BMP']);

tifFile = 'DCR_F_574'; 

bb = 100;
I = imread([bmpDir, bmpList(bb).name]);
I = rgb2gray(I);
imshow(I)
%%
formatLabelS = {'LZW', 'PackBits', 'Deflate'};%'None'};

t = cell(size(formatLabelS));

for mm = 1:numel(formatLabelS)
    t{mm} = Tiff([tifFile '_', formatLabelS{mm}, '.tif'],'w');
end    

for bb = 1:numel(bmpList)
    I = imread([bmpDir, bmpList(bb).name]);
    I = rgb2gray(I);

    for mm = 1:numel(formatLabelS)
        t{mm}.setTag('Photometric', Tiff.Photometric.MinIsBlack) %gray image zero is interpreted as black
        t{mm}.setTag('ImageLength', size(I,1));
        t{mm}.setTag('ImageWidth', size(I,2));
        t{mm}.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
        t{mm}.setTag('BitsPerSample', 8) %uint8 image
        t{mm}.setTag('Compression', Tiff.Compression.(formatLabelS{mm}));
        t{mm}.write(I);
        t{mm}.writeDirectory()
    end
end
for mm = 1:numel(formatLabelS)
    t{mm}.close()
end


%%
