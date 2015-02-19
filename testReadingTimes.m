saveDir = '/Users/ajaver/Desktop/test_formats/';

totalN = 2048*2048*450;
clear I
disp('Raw Data fread')
tic
FID = fopen([saveDir, 'raw_data'], 'r');
I = fread(FID, totalN, 'uint8');
I = reshape(I, [2048, 2048, 450]);
fclose(FID);
toc

%%
clear I
disp('Raw Data fread and cells')
tic
FID = fopen([saveDir, 'raw_data'], 'r');
totpix = 2048*2048;
I = cell(1,450);
for mm = 1:450
    I{mm} = fread(FID, totpix, 'uint8');
    I{mm} = reshape(I{mm}, [2048, 2048]);
end
fclose(FID);
toc

%%
clear I
disp('Raw Data memmap')
tic
I = memmapfile([saveDir, 'raw_data'], 'Format', 'uint8');
I = reshape(I.Data, [2048, 2048, 450]);
toc
%%
clear I
disp('Raw Data cells and memmap')
tic
datmap = memmapfile([saveDir, 'raw_data'], 'Format', 'uint8');
totpix = 2048*2048;
I = cell(1,450);
for mm = 1:450
    I{mm} = datmap.Data((1:totpix) + (mm-1)*totpix);
    I{mm} = reshape(I{mm}, [2048, 2048]);
end
toc

%%
clear I
disp('TIFF LZW')
tic
fname = [saveDir, 'Tiff_LZW.tiff'];
info = imfinfo(fname);
%I = [];
%I(info(1).Width, info(1).Height, numel(info)) = 0;%faster initialization than zeros(m,n,o); 
I = cell(size(info));
for mm = 1:numel(info)
    I{mm} = imread(fname, mm,'Info', info);
end
toc

%%
clear I
disp('TIFF Uncompressed')
tic
fname = [saveDir, 'Tiff_Uncompressed.tiff'];
info = imfinfo(fname);
I = cell(size(info));
%I(info(1).Width, info(1).Height, numel(info)) = 0;%faster initialization than zeros(m,n,o); 
for mm = 1:numel(info)
    I{mm} = imread(fname, mm,'Info', info);
end
toc

%%
clear I
disp('BMP')
tic
bmpDir = [saveDir 'BMP' filesep];
I = cell(1,450);
for mm = 1:numel(I)
    I{mm} = imread(sprintf('%s%03i.bmp', bmpDir, mm-1));
end
toc
