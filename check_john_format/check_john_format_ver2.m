mainDir = '/Users/ajaver/Desktop/John_Format/';

ff = memmapfile([mainDir 'DCR_D_1237.PVSeq']);
iniBlocks = strfind(ff.Data', 'PV01');

timeStamps = zeros(size(iniBlocks));
for kk = 1:numel(iniBlocks)
    timeStamps(kk) = typecast(ff.Data(iniBlocks(kk)+(4:7) ), 'uint32');
end
