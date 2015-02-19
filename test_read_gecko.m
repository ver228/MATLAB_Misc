addpath('/Users/ajaver/Dropbox/MATLAB/mmread')
fileName = '/Users/ajaver/Desktop/CaptureTest_90pc_Ch1_02022015_141431.mjpg';

for kk = 1000:2000
    disp(kk)
    info = mmread(fileName, kk, [], false, true);
end

