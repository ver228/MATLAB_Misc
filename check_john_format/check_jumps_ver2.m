mainDir ='/Users/ajaver/Desktop/test_jumpy_tiff_20150203/';

prefix = 'test_MPC_F_';

N_chunk = 3;
ini_chunk = 1376;
N_frames= 1500;
diff_range = zeros(1, N_chunk*N_frames-1);
timeStamps = zeros(1, N_chunk*N_frames);

tot_frames = 0;
mask_prev = [];
for chunk_index = ini_chunk + (0:(N_chunk-1))
    fileStr = sprintf('%s%d', prefix, chunk_index);
    fileName = [mainDir fileStr '.tif'];
    
    ff = memmapfile([mainDir fileStr '.PVSeq']);
    iniBlocks = strfind(ff.Data', 'PV01');

    %fileName = '/Users/ajaver/Desktop/DCR_D_1237_LZW.tif';
    infoImage=imfinfo(fileName);
    
    
    for frame = 1:numel(infoImage)
        tot_frames = tot_frames + 1;
        disp(frame)
        I = imread(fileName,'Index',frame,'Info',infoImage);
        mask = I==0;
        if ~isempty(mask_prev)
            mask_join = ~(mask|mask_prev);
            dd = abs(double(I(mask_join))-double(I_prev(mask_join)));
            
            diff_range(tot_frames-1) = mean(dd(:));
        end
        I_prev = I;
        mask_prev = mask;
        
        timeStamps(tot_frames) = ...
            typecast(ff.Data(iniBlocks(frame)+(4:7) ), 'uint32');
        
    end
end
%%
diff_range = diff_range(1:(tot_frames-1));
timeStamps = timeStamps(1:tot_frames);
%%
bad = diff(timeStamps(1:end))~=1;
index = 1:numel(bad);

figure, hold on
plot(diff_range)
hh = plot(index(bad), diff_range(bad), 'rx');
xlabel('frame')
ylabel('Image abs difference')
legend(hh, 'Timestamp difference != 1')
%%
