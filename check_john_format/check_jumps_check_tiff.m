mainDir ='/Users/ajaver/Desktop/test_jumpy_tiff_20150203/';

prefix = 'test_MPC_F_';

N_chunk = 3;
ini_chunk = 1376;
N_frames= 1500;
diff_range = zeros(1, N_chunk*N_frames-1);
timeStamps = zeros(1, N_chunk*N_frames);

mask_prev = [];
tot_frames = 0;

for chunk_index = ini_chunk + (0:(N_chunk-1))
    disp(chunk_index)
    fileStr = sprintf('%s%d', prefix, chunk_index);
    
    ff = memmapfile([mainDir fileStr '.PVSeq']);
    iniBlocks = strfind(ff.Data', 'PV01');
    
    beginIndex = iniBlocks(1);
    
    fileName = [mainDir fileStr '.tif'];
    
        
    infoImage=imfinfo(fileName);
    for frame = 1:numel(iniBlocks)
        I_tiff = imread(fileName,'Index',frame,'Info',infoImage);
        
        tot_frames = tot_frames + 1;
        
        if frame<numel(iniBlocks)
            nextIndex = iniBlocks(frame+1)-1;
        else
            nextIndex = numel(ff.Data);
        end
        
        
        if nextIndex - beginIndex < 2048
            %not enough space for the header, there must be P0V1 in the header
            continue
        end
        disp(frame)
        %I(:) = 0;
        
        I = decode_DRC(ff.Data, [beginIndex+2048, nextIndex])';
        beginIndex = nextIndex+1;
        
        dd =  abs(double(I) - double(I_tiff));
        diff_range(tot_frames) = mean(dd(:));
        %{
        mask = I==0;
        if ~isempty(mask_prev)
            mask_join = ~(mask|mask_prev);
            diff_range(tot_frames-1) = mean(abs(double(I(mask_join)) ...
                - double(I_prev(mask_join))));
            
        end
        I_prev = I;
        mask_prev = mask;
        
        timeStamps(tot_frames) = ...
            typecast(ff.Data(iniBlocks(frame)+(4:7) ), 'uint32');
        
        %figure, imshow(I)
        %}
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
%}

%%
