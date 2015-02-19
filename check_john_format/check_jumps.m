mainDir ='/Users/ajaver/Desktop/test_jumpy_tiff_20150203/';

fileList = {'test_MPC_C_1376.tif', 'test_MPC_C_1377.tif', 'test_MPC_C_1378.tif'};

N_frames = 1500;
diff_range = zeros(1, numel(fileList)*N_frames-1);

nn = 1;
for fileStr = fileList
    fileName = [mainDir fileStr{1}];
    
    %fileName = '/Users/ajaver/Desktop/DCR_D_1237_LZW.tif';
    infoImage=imfinfo(fileName);
    
    mask_prev = [];
    for frame = 1:numel(infoImage)
        disp(frame)
        I = imread(fileName,'Index',frame,'Info',infoImage);
        mask = I==0;
        if ~isempty(mask_prev)
            mask_join = ~(mask|mask_prev);
            dd = abs(double(I(mask_join))-double(I_prev(mask_join)));
            nn = nn + 1;
            diff_range(nn) = mean(dd(:));
        end
        I_prev = I;
        mask_prev = mask;
    end
end

%%
figure
plot(diff_range)
xlabel('frame')
ylabel('Image abs difference')
