%mainDir ='/Users/ajaver/Desktop/test_jumpy_tiff_20150203/';
mainDir = '/Volumes/Mrc-pc/Data/AEJ/20150202_MasterSlave/';

prefix = 'test_MPC_E_';

saveDir = '/Volumes/ajaver$/check_jumps_results/';
if ~exist(saveDir, 'dir'), mkdir(saveDir), end

saveName = sprintf('%s%s_results.mat', saveDir, prefix);

N_chunk = 7;
ini_chunk = 1374;
N_frames= 1500;
diff_range = nan(1, N_chunk*N_frames-1);
timeStamps = nan(1, N_chunk*N_frames);

I_prev = [];
tot_frames = 0;

for chunk_index = ini_chunk + (0:(N_chunk-1))
    disp(chunk_index)
    fileStr = sprintf('%s%d', prefix, chunk_index);
    
    fileName = [mainDir fileStr '.PVSeq'];
    if ~exist(fileName, 'file')
        %chunk does not found jump to the next N_frames block
        tot_frames = tot_frames + N_frames;
        I_prev = [];
        continue
    end
    ff = memmapfile(fileName);
    iniBlocks = strfind(ff.Data', 'PV01');
    
    beginIndex = iniBlocks(1);
    for frame = 1:numel(iniBlocks)
        
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
        
        I = decode_DRC(ff.Data, [beginIndex+2048, nextIndex]);
        beginIndex = nextIndex+1;
        
        %{
        mask = I==0;
        if ~isempty(I_prev)
            mask_join = ~(mask|mask_prev);
            diff_range(tot_frames-1) = imMaskDiff(I,I_prev);
            mean(abs(double(I(mask_join)) ...
                - double(I_prev(mask_join))));
            
        end
        mask_prev = mask;
        %}
        %
        if ~isempty(I_prev)
            diff_range(tot_frames-1) = imMaskDiff(I,I_prev);
        end
        %}
        I_prev = I;
        
        timeStamps(tot_frames) = ...
            typecast(ff.Data(iniBlocks(frame)+(4:7) ), 'uint32');
        
    end
    if mod(chunk_index,10) == 0
        save(saveName, 'diff_range', 'timeStamps', 'tot_frames', 'chunk_index');
    end
end
%%
diff_range = diff_range(1:(tot_frames-1));
timeStamps = timeStamps(1:tot_frames);
save(saveName, 'diff_range', 'timeStamps', 'tot_frames', 'chunk_index');

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
