rootDir = '/Users/ajaver/Desktop/';
tifFile = 'DCR_A_864_crop'; 


bb = 100;
I = imread([rootDir, tifFile, '.tif'], 'Index', bb);
infoTiff = imfinfo([rootDir, tifFile, '.tif']);

imshow(I)
%%
formatLabelS = {'LZW', 'PackBits', 'Deflate'};%'None'};

t = cell(size(formatLabelS));

for mm = 1:numel(formatLabelS)
    t{mm} = Tiff([rootDir, tifFile '_', formatLabelS{mm}, '.tif'],'w');
end    

for bb = 1:200%numel(infoTiff)
    disp(bb)
    I = imread([rootDir, tifFile, '.tif'], 'Index', bb, 'Info', infoTiff);

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
