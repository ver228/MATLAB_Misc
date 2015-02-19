mainDir = '/Users/ajaver/Desktop/John_Format/';

bmp_prefix = [mainDir, 'BMP/DCR_D_1237_'];
bmp_ini = 73227;
I = imread(sprintf('%s%i.BMP', bmp_prefix, bmp_ini));
I = I(:,:,1);
ff = memmapfile([mainDir 'DCR_D_1237.PVSeq']);

dat = ff.Data(1:5000000);
%%
zerosInd = find(dat==0);
dum = diff(zerosInd);
bigJumpsInd = find(dum>2000);

figure, hold on
for nn = 1:numel(bigJumpsInd)
    word = dat((zerosInd(bigJumpsInd(nn))-100): zerosInd(bigJumpsInd(nn)+1));
    
    plot(word)
end

%% read one image
%343254
dat = ff.Data(1:343114);
plot(dat)

%%
figure,
subplot(3,1,1)
plot(dat(find(dat==8,1)+ (-5:5000))')
%%
Idum = I';
subplot(3,1,2)
plot(Idum(1:300))
%%

figure,
subplot(3,1,1)
plot(dat(end-10000:end))

Idum = I';
subplot(3,1,2)
plot(Idum(:,end-1))

%%
figure,
subplot(2,1,1)
plot(dat(find(dat==8,1):end)')
subplot(2,1,2)
plot(Idum(Idum~=200))
%%

iniIndex = find(dat==8,1);

buff = zeros(size(I));
tot = uint64(1);

kk = iniIndex;
while kk <= numel(dat)
    
    if dat(kk) ~= 0
        buff(tot) = dat(kk);
        tot = tot + 1;
        kk = kk + 1;
    else
        disp([dat(kk+2), dat(kk+1)])
        NN = uint64(typecast([dat(kk+2) dat(kk+1)],'uint16'));
        
        %nZeros = nZeros+1;
        %double(dat(kk+1))*256 + double(dat(kk+2));
        disp(NN)
        disp(kk-iniIndex) 
        
        %break;
        vv = tot + (0:NN);
        buff(vv) = 200;
        tot = vv(end);
        kk = kk + 3;
    end
end
%%



%subplot(3,1,3)
%plot(I(:,1))

