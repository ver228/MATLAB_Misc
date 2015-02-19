addpath('../local_threshold/')

vidObj = VideoReader('~/Documents/N2_20141202.mov');

iniFrame = 1e4;

Iprev = rgb2gray(vidObj.read(iniFrame));
Lprev = [];


%tiffObj = Tiff('Results.tif','w');
writerObj = VideoWriter('results.avi');
open(writerObj);
for frame = 1:450 + iniFrame
    
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
    
    %{
    tiffObj.setTag('Photometric', Tiff.Photometric.RGB) %gray image zero is interpreted as black
    tiffObj.setTag('ImageLength', size(Irgb,1));
    tiffObj.setTag('ImageWidth', size(Irgb,2));
    tiffObj.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
    tiffObj.setTag('BitsPerSample', 8) %uint8 image
    tiffObj.setTag('SamplesPerPixel', 3) %uint8 image
    
    tiffObj.setTag('Compression', Tiff.Compression.Deflate);
    tiffObj.write(Irgb);
    tiffObj.writeDirectory()
    %}
    writeVideo(writerObj,Irgb);
    disp(frame)
end
%tiffObj.close()
writerObj.close();