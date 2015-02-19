tmpDir = '/Users/ajaver/Dropbox/MATLAB/worm_movies/temp_movies/'; %use fullpath mmread does not like relative directories
addpath('../local_threshold/')
addpath('../mmread/')
%fileName = '/Volumes/MyPassport/Worms/Movies_DinoLite/Exp_20141202/A003 - 20141202_165718.wmv';
%fileName = '/Volumes/MyPassport/Worms/Movies_DinoLite/Exp_20141205/A007 - 20141205_185714.wmv';
%fileName = '/Users/ajaver/Desktop/A009 - 20141210_193017.wmv';

%fileName = '/Volumes/ajaver$/Video/Exp2-20141205/A007 - 20141205_185714.wmv';
%saveName = '/Volumes/ajaver$/Video/Exp2-20141205/A007_results.mat';
fileName = '/Volumes/ajaver$/Video/Exp4-20141216/A001 - 20141216_195148.wmv';
saveName = '/Volumes/ajaver$/Video/Exp4-20141216/A001_results.mat';
saveNameBgnd = '/Volumes/ajaver$/Video/Exp4-20141216/A001_bgnd.mat';


% Copy file into the local drive
FLAG_COPY_FILE = false;
if FLAG_COPY_FILE
    [pathStr,name,ext] = fileparts(fileName);
    tmpName = [tmpDir, name, ext];
    if ~exist(tmpName, 'file')
        copyfile(fileName, tmpName);
    end
    fileName = tmpName;
end
%%
initialTime = 1;
bufferSize = 20;
bufferDeltaTime = 60;

%% 
TOTCHUNK = 600;
clear dat
dat.frames = [];
while isempty(dat.frames)
    TOTCHUNK = TOTCHUNK -1;
    [dat, ~] = mmread(fileName, [], bufferDeltaTime*[TOTCHUNK-1, TOTCHUNK]);
end
%%


datInfo = mmread(fileName, 1);


iBuff = ImageBuffer(datInfo.height, datInfo.width, bufferSize);
for im = 1:bufferSize
    [dat, ~] = mmread(fileName, [], initialTime + bufferDeltaTime*(im-1)+ [0 0.1]);
    iBuff.add(rgb2gray(dat.frames(1).cdata));
    disp(im)
end

Idum = sort(iBuff.data,3);
Ibgnd = Idum(:,:,round(bufferSize*0.7));
Ibgnd_1 = Ibgnd;
save(saveNameBgnd, 'Ibgnd_1', 'initialTime', 'bufferSize', 'bufferDeltaTime')
%figure, imshow(Ibgnd)
%%
BUFFSIZE = 1e8;
totData = 0;
frameN = 0;
totWorms = 0;
allProps = zeros(14,BUFFSIZE);
coordPrev = [];
%%
for nChunk = 1:TOTCHUNK
    fprintf('***** Chunk %i *****\n', nChunk)
    [dat, ~] = mmread(fileName, [], initialTime + bufferDeltaTime*[nChunk-1, nChunk]);
    if nChunk > bufferSize
        iBuff.add(rgb2gray(dat.frames(end).cdata));
        Idum = sort(iBuff.data,3);
        Ibgnd = Idum(:,:,round(bufferSize*0.7));
        clear Idum
        newName = sprintf('Ibgnd_%i', nChunk+10);
        a.(newName) = Ibgnd;
        save(saveNameBgnd,'-struct', 'a', newName, '-append')
        clear a
        %figure, imshow(Ibgnd)
    end
    
    %propsChunk = cell(size(dat.frames));
    for im = 1:numel(dat.frames)
        if mod(im,10) == 0, disp(im); end
        frameN = frameN + 1;
        I = dat.frames(im).cdata(:,:,1);
        Idiff = Ibgnd-I;
        mask = Idiff>=30;
        props = regionprops(mask, I, 'Area', 'Centroid', ...
            'MajorAxisLength', 'MinorAxisLength', 'Perimeter', ...
            'Solidity', 'Eccentricity', 'Orientation');
        
        props = props([props.Area]>5);
        %propsChunk{im} = props;
        if isempty(props)
            coordPrev = [];
            continue;
        end
        
        coord = reshape([props.Centroid],2,[])';
        speed = zeros(size(coord,1),1);
        if ~isempty(coordPrev)
            costMatrix = pdist2(coord,coordPrev);
            costMatrix(costMatrix>40) = Inf;
            assigment = munkres(costMatrix);
            
            indexList = zeros(size(assigment));
            for ll = 1:numel(indexList)
                if assigment(ll)~=0
                    indexList(ll) = indexListPrev(assigment(ll));
                    speed(ll) = costMatrix(ll, assigment(ll));
                else
                    totWorms = totWorms +1;
                    indexList(ll) = totWorms;
                end
            end
            
        else
            indexList = totWorms + (1:size(coord,1));
            totWorms = indexList(end);
        end
        %% 
        %wormIndex, frameNumber, x, y, majorAxis, minorAxis, 
        %solidity, eccentricity, compactness, orientation, speed, behaviour
        vv = totData + (1:numel(indexList));
        totData = vv(end);
        allProps(1,vv) = indexList;
        allProps(2,vv) = frameN;
        allProps(3,vv) = coord(:,1);
        allProps(4,vv) = coord(:,2);
        allProps(5,vv) = [props.Area];
        allProps(6,vv) = [props.Perimeter];
        allProps(7,vv) = [props.MajorAxisLength];
        allProps(8,vv) = [props.MinorAxisLength];
        allProps(9,vv) = [props.Solidity];
        allProps(10,vv) = [props.Eccentricity];
        allProps(11,vv) = [props.Perimeter].^2./[props.Area];
        allProps(12,vv) = [props.Orientation];
        allProps(13,vv) = speed;
        
        
        %function angleinradians = getabsoluteangle(xold, yold, xnew, ynew)
        %angleinradians = atan2(ynew-yold, xnew-xold);
        %end

        
        
        %props = regionprops(mask, I, 'Area', 'Centroid', ...
        %    'MajorAxisLength', 'MinorAxisLength', 'Perimeter', ...
        %    'Solidity', 'Eccentricity', 'Orientation');
        
        indexListPrev = indexList;
        coordPrev = coord;
    end
    
    if mod(nChunk,50) == 0
        allProps_partial = allProps(:,1:totData);
        save('results_partial2.mat', 'allProps_partial', '-v7.3')
        clear allProps_partial
    end
    %allProps = [allProps, propsChunk]; %#ok<AGROW>
    %clear dat propsChunk props
end
%%
%wormIndex, frameNumber, x, y, majorAxis, minorAxis, 
%solidity, eccentricity, compactness, orientation, speed, behaviour
allProps = allProps(:,1:totData);
save(saveName, 'allProps', '-v7.3')

%%
X = sparse( allProps(2,:), allProps(1,:), allProps(3,:)); 
Y = sparse( allProps(2,:), allProps(1,:), allProps(4,:)); 
plot(X,Y, '.')
%}

%{
N = sum(cellfun(@numel, allProps));
AA = zeros(2,N);
tot = 0;
for im = 1:numel(allProps)
    area = [allProps{im}.Area];
    %disp(numel(area)
    vv = tot + (1:numel(area));
    disp(numel(vv))
    tot = vv(end);
    AA(2,vv) = area;
    AA(1,vv) = im;
end
plot(AA(1,:), AA(2,:), '.')

 
%%
%h5create('results.h5','/dum',Inf, 'ChunkSize',1000)
%h5disp('myfile.h5');
h5write('myfile.h5', '/dun', allProps{1});
%allProps
%}

