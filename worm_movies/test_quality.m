addpath('../mmread/')


I_high = imread('/Users/ajaver/Desktop/DCR_D_F1000.BMP');

dat = mmread('/Users/ajaver/Desktop/shot_movie.avi',1000);
I_low = dat.frames.cdata;

close all
figure, imshow(I_high)
figure, imshow(I_low)