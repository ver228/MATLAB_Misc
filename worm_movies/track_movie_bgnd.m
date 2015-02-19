addpath('../local_threshold/')

vidObj = VideoReader('~/Documents/N2_20141202.mov');

iniFrame = 6e4;
buffSize = 30;
Ibuff = zeros(vidObj.Height, vidObj.Width, buffSize);

for im = 1:buffSize
    Ibuff(:,:, im) = rgb2gray(vidObj.read(iniFrame + im -1));
    disp(im)
end
%%
delT = 60;

Ibuff2 = zeros(vidObj.Height, vidObj.Width, buffSize);

for im = 1:buffSize 
    Ibuff2(:,:, im) = rgb2gray(vidObj.read(iniFrame + (im -1)*delT));
    disp(im)
end

Ib = uint8(max(Ibuff2, [], 3) - Ibuff2(:,:,1));
%%
[a, b] = graythresh(uint8(Ib));
figure 
imshow(Ib>255*a)

%%
Imax = zeros(size(vidObj.Height, vidObj.Width));
for im = 1e4:1000:6e4
    Imax = max(Imax, rgb2gray(vidObj.read(im)));
end
%%
%%
Idiff =Imax-uint8(Ibuff(:,:, 1));
figure, imshow(255-Idiff)
figure, imshow(~bradley(Idiff, [50, 50], 20));
%hist(double(Idiff(:)),100)
%%
%%
Imax = zeros(size(vidObj.Height, vidObj.Width));
for im = 1e4:1000:6e4
    Imax = max(Imax, rgb2gray(vidObj.read(im)));
end


%{
Iprev = rgb2gray(vidObj.read(iniFrame));
Lprev = [];

tiffObj = Tiff('Results.tif','w');

for frame = (1:200) + iniFrame
    
    I = rgb2gray(vidObj.read(frame));
    
    Ibw = ~bradley(I, [50, 50], 20);
    L = bwlabel(Ibw, 8);
    Idiff = I-Iprev;
    
    uL = unique(L(Idiff>6));
    Lmove = zeros(size(I), 'uint16');
    for kk = 1:numel(uL)
        if uL(kk) ~= 0
            Lmove(L==uL(kk)) = kk;
        end
    end
    
    
    
    if ~isempty(Lprev)
        %%
        Lstatic = L;
        Lstatic(Lmove>0) = 0;
        Lstatic(Lprev==0)= 0;
        uL = unique(Lstatic);
        Lstatic = zeros(size(L), 'uint16');
        for kk = 1:numel(uL)
            if uL(kk) ~= 0
                Lstatic(L==uL(kk)) = kk;
            end
        end
    else
        Lstatic = zeros(size(L), 'uint16');
        
    end
    
    
    Lnew = Lmove + Lstatic;
    
    Iprev = I;
    Lprev = Lnew;
    
    
    %%
    Irgb = repmat(I, 1, 1, 3);
    Idum = I;
    Idum(Lstatic>0) = 255;
    Irgb(:,:,1) = Idum;
    
    Idum = I;
    Idum(Lmove>0) = 255;
    Irgb(:,:,2) = Idum;
    
    %figure,imshow(Irgb, [])
    
    
    tiffObj.setTag('Photometric', Tiff.Photometric.RGB) %gray image zero is interpreted as black
    tiffObj.setTag('ImageLength', size(Irgb,1));
    tiffObj.setTag('ImageWidth', size(Irgb,2));
    tiffObj.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
    tiffObj.setTag('BitsPerSample', 8) %uint8 image
    tiffObj.setTag('SamplesPerPixel', 3) %uint8 image
    
    tiffObj.setTag('Compression', Tiff.Compression.Deflate);
    tiffObj.write(Irgb);
    tiffObj.writeDirectory()
    
    disp(frame)
end
tiffObj.close()
%}
%{
figure,
imshow(Ibw)

figure,
imshow(I,[])

figure
imshow(Idiff, [])
%}

%figure, imshow(I,[])
