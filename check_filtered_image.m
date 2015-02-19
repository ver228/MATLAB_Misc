addpath('/Users/ajaver/Dropbox/MATLAB/local_threshold/')

tiff_name = '/Users/ajaver/Desktop/DCR_D_1237.tif';

tiff_new = '/Users/ajaver/Desktop/DCR_D_1237_new.tif';
tiff_id = Tiff(tiff_new,'w');

infoImage=imfinfo(tiff_name);

for frame = 1:numel(infoImage)
    disp(frame)
    I = imread(tiff_name,'Index',frame,'Info',infoImage);
    
    mask = I~=0 & I < 150;
    mask = bwareaopen(mask,25);
    
    L = bwlabel(mask);
    badL = unique([[L(:,1); L(:,end)]', L(1,:), L(end,:)]);
    badL(badL ==0) = [];
    for bb = badL
        L(L==bb) = 0;
    end
    mask = bwmorph(L, 'dilate', 5);
    
    I(~mask) = 0;
    
    tiff_id.setTag('Photometric', Tiff.Photometric.MinIsBlack) %gray image zero is interpreted as black
    tiff_id.setTag('ImageLength', size(I,1));
    tiff_id.setTag('ImageWidth', size(I,2));
    tiff_id.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
    tiff_id.setTag('BitsPerSample', 8) %uint8 image
    tiff_id.setTag('Compression', Tiff.Compression.LZW);
    tiff_id.write(I);
    tiff_id.writeDirectory()
end
%imshow(I)

tiff_id.close();
%{
%%
L = bwlabel(I~=0);
badL = unique([[L(:,1); L(:,end)]', L(1,:), L(end,:)]);
badL(badL ==0) = [];
for bb = badL
    L(L==bb) = 0;
end
dat = I(L~=0);

level = graythresh(dat);
mask = I~=0 & ~im2bw(I, level);
mask = bwareaopen(mask,5);
imshow(mask)

%%
mask = I~=0 & ~bradley(I,[50,50], 0.2);
mask = bwareaopen(mask,25);
imshow(mask)
%%
L = bwlabel(I~=0);
badL = unique([[L(:,1); L(:,end)]', L(1,:), L(end,:)]);
badL(badL ==0) = [];
for bb = badL
    L(L==bb) = 0;
end
dat = I(L~=0);

level = graythresh(dat);
mask = I~=0 & ~im2bw(I, level);
mask = bwareaopen(mask,5);
imshow(mask)
%}