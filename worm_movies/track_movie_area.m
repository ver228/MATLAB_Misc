addpath('../local_threshold/')

vidObj = VideoReader('~/Documents/N2_20141202.mov');

iniFrame = 6e4;

Iprev = rgb2gray(vidObj.read(iniFrame));
Lprev = [];
%{
% Initialize buffer

buffDelFrame = 60; % time between frames in the buffer (give enough for the worms to move)
buffSize = 30; % number of frames in the buffer

Ibuff = zeros(vidObj.Height, vidObj.Width, buffSize);
for im = 1:buffSize 
    Ibuff(:,:, im) = rgb2gray(vidObj.read(iniFrame + (im -1)*buffDelFrame));
    disp(im)
end
Ibgnd = uint8(max(Ibuff, [], 3));
%}
%%
writerObj = VideoWriter('results.avi');
open(writerObj);
for frame = (1:200) + iniFrame
    
    I = rgb2gray(vidObj.read(frame));
    
    Ibw = ~bradley(I, [50, 50], 20);
    %{
    Ib = Ibgnd-I;
    thresh = graythresh(Ib);
    Ibw = (Ib)>255*thresh;
    %}
    %imshow(Ibw,[])
    %%
    L = bwlabel(Ibw, 8);
    Idiff = I-Iprev;
    
    uL = unique(L(Idiff>6));
    
    tot = 0;
    Lmove = zeros(size(I), 'uint16');
    for kk = 1:numel(uL)
        if uL(kk) ~= 0
            tot = tot +1;
            Lmove(L==uL(kk)) = tot;
        end
    end
    
    
    
    if ~isempty(Lprev)
        Lstatic = L;
        Lstatic(Lmove>0) = 0;
        Lstatic(Lprev==0)= 0;
        uL = unique(Lstatic);
        Lstatic = zeros(size(L), 'uint16');
        for kk = 1:numel(uL)
            if uL(kk) ~= 0
                tot = tot + 1;
                Lstatic(L==uL(kk)) = tot;
            end
        end
    else
        Lstatic = zeros(size(L), 'uint16');
    end
    
    
    Lnew = Lmove + Lstatic;
    props = regionprops(Lnew, 'PixelIdxList', 'Area');
    
    Lnew = zeros(size(I));
    for kk = 1:numel(props)
        if props(kk).Area < 700
            Lnew(props(kk).PixelIdxList) = kk;
        end
    end
    %imshow(Lnew)
    

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
    
    writeVideo(writerObj,Irgb);
    disp(frame)
end
writerObj.close();
%%
    
