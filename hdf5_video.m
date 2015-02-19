fileName = '/Volumes/ajaver$/DinoLite/Results/Exp5-20150116-2/A002 - 20150116_140923.hdf5';

vid = VideoWriter('test2.m4v', 'MPEG-4');
vid.FrameRate = 50;
open(vid);
infoFile =  h5info(fileName, '/bgnd');

tic
chunkSize = infoFile.ChunkSize;
for kk = 1:infoFile.Dataspace.Size(3)
    disp(kk)
    writeVideo(vid, h5read(fileName, '/bgnd', [1,1,kk],chunkSize));
end
close(vid)
toc