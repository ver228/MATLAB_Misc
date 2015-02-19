%DONE:
%changed: object detection size is now interpreted in terms of um^2 instead of pixels, to bring it in line with zentracker 2.8
%changed: valid duration check is now interpreted in terms of seconds instead of frames, to bring it in line with zentracker 2.8
%improved: object detection size and valid duration conversions are now backwards-compatible with earlier analysisdata savefiles
%TODO:
%add: batch automatic reversal detection
%improve: current file waitbar should just have its message changed when switching to a new file instead of deleting and recreating it
%improve: first set the interpreter to none before setting the message as the filename

function zenbatch

    version = '1.3';
    
    CONST_BEHAVIOUR_UNKNOWN = 0;
    CONST_BEHAVIOUR_FORWARDS = 1;
    CONST_BEHAVIOUR_REVERSAL = 2;
    CONST_BEHAVIOUR_OMEGA = 3;
    CONST_BEHAVIOUR_INVALID = 4;
    
    CONST_GUI_SORT_ALPHABETICALLY = 1;
    CONST_GUI_SORT_BYDATE_ASCENDING = 2;
    CONST_GUI_SORT_BYDATE_DESCENDING = 3;
    
    sortby = CONST_GUI_SORT_BYDATE_DESCENDING;
    onlynew = false;
    
    directory = [];
    files = {};
    selectedfiles = {};
    readerfailuredisplayed = [];
    
    disklike = strel('disk', 1, 4); %structuring element used for erosion and dilation ([0 1 0; 0 0 0; 0 1 0])
    
    moviecache = struct('data', []);
    cachedframe = [];
    cachedindex = NaN;
    
    gradnormmatrix = [];
    gradnorm = false;
    timenorm = false;
    
    moviefiles = {};
    movieindicator = [];
    frameindicator = [];
    lastframe = NaN;
    framerate = NaN;

    objects = []; %struct('frame', [], 'time', [], 'x', [], 'y', [], 'length', [], 'width', [], 'area', [], 'perimeter', [], 'eccentricity', [], 'speed', [], 'directionchange', [], 'behaviour', []);
    scalingfactor = NaN;
    meanperimeter = NaN;
    
    detectionarea = []; %logical matrix representing which pixels can be thresholded
    measurementarea = []; %logical matrix representing centroids at which pixels can be considered valid
    
    validspeedmin = 0;
    validspeedmax = 0;
    validlengthmin = 0;
    validlengthmax = 0;
    validwidthmin = 0;
    validwidthmax = 0;
    validareamin = 0;
    validareamax = 0;
    validperimetermin = 0;
    validperimetermax = 0;
    valideccentricitymin = 0;
    valideccentricitymax = 0;
    
    validdurationcheckstyle = NaN;
    validdurationminimum = 0;
    
    thresholdsizemin = 0;
    thresholdsizemax = 0;
    thresholdintensity = 0;
    thresholdspeedmax = 0;
    
    moviereaderobjects = struct([]);
    qtreaders = struct([]);
    tiffservers = struct([]);
    avireadworks = false;
    qtserveravailable = false;
    tiffserveravailable = false;
    
    oldwarningstate = [];
    
    pixelmax = 255; %the maximum intensity value of a pixel. defaults to that of an 8-bit image, but will be queried and updated (if possible) when loading a new movie
    
    handles.fig = figure('Name',['Zen Tracker batch processor version ' version],'NumberTitle','off', ...
        'Visible','on','Color',get(0,'defaultUicontrolBackgroundColor'), 'Units','Normalized',...
        'DefaultUicontrolUnits','Normalized', 'DeleteFcn', @savesettings);
    
    handles.datapanel = uipanel(handles.fig,'Title','File selection','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.00 0.00 1.00 1.00]);
    handles.folder = uicontrol(handles.datapanel,'Style','Edit','String',directory,'HorizontalAlignment','left','BackgroundColor','w','Position',[0.00 0.95 0.50 0.05]);
    handles.onlynew = uicontrol(handles.datapanel,'Style','Checkbox','String', 'Hide analysed', 'Value', onlynew, 'Position',[0.50 0.95 0.10 0.05], 'Callback', @updateonlynew);
    handles.sortby = uicontrol(handles.datapanel, 'Style','Popupmenu','String',{'Alphabetical', 'Ascending by date', 'Descending by date'},'Value',sortby,'Position',[0.60 0.95 0.10 0.05],'Callback',@setsortby);
    handles.browse = uicontrol(handles.datapanel,'Style','Pushbutton','String','Browse','Position',[0.85 0.95 0.15 0.05],'Callback',@browse);
    handles.files = uicontrol(handles.datapanel,'Style','Listbox','String',files, 'BackgroundColor','w', 'Position',[0.00 0.15 1.00 0.80],'Max',intmax('int32'),'Callback',@selectfile);
    handles.updatefiles = uicontrol(handles.datapanel, 'Style','Pushbutton','String','Refresh','Position',[0.70 0.95 0.15 0.05],'Callback',@updatefilelist);
    handles.analyse = uicontrol(handles.datapanel, 'Style', 'Pushbutton', 'String', 'Analyse', 'Position',[0.25 0.00 0.75 0.15],'Callback',@analyse);
    handles.dotrack = uicontrol(handles.datapanel, 'Style', 'Checkbox', 'String', 'Detect and track objects', 'Value', 1, 'Position',[0.00 0.10 0.25 0.05]);
    handles.dovalidity = uicontrol(handles.datapanel, 'Style', 'Checkbox', 'String', 'Check validity', 'Value', 1, 'Position',[0.00 0.05 0.25 0.05]);
    handles.doduration = uicontrol(handles.datapanel, 'Style', 'Checkbox', 'String', 'Check duration', 'Value', 0, 'Position',[0.00 0.00 0.25 0.05]);
    
    initialize;
    loadsettings;
    updatefilelist;
    
    function initialize
        
        oldwarningstate = warning('query', 'all'); %we store the warning state prior to launching zenbatch, to enable us to restore it when zenbatch exits
        
        %do not display FunctionToBeRemoved warnings. In terms of native readers, we use Videoreader class (the newest/current native way to read videos as of 2012b), it's just that for the sake of other Matlab versions and other platforms, mmreader, avireader, etc, are still available as fallback options.
        warning('off', 'MATLAB:avifinfo:FunctionToBeRemoved');
        warning('off', 'MATLAB:aviinfo:FunctionToBeRemoved');
        warning('off', 'MATLAB:aviread:FunctionToBeRemoved');
        warning('off', 'MATLAB:mmreader:isPlatformSupported:FunctionToBeRemoved');
        warning('off', 'MATLAB:audiovideo:avifinfo:FunctionToBeRemoved');
        warning('off', 'MATLAB:audiovideo:aviinfo:FunctionToBeRemoved');
        warning('off', 'MATLAB:audiovideo:aviread:FunctionToBeRemoved');
        warning('off', 'MATLAB:audiovideo:mmreader:isPlatformSupportedToBeRemoved');
        
        %make sure that QTFrameServer.jar is added to the java class path if and only if it is available
        try
            
            qtjavafound = false;
            qtserveravailable = false;
            tiffserveravailable = false;
            
            %we first check the java class path
            classpath = javaclasspath;
            for i=1:numel(classpath)
                if strfind(classpath{i}, 'QTFrameServer.jar') == numel(classpath{i}) - numel('QTFrameServer.jar') + 1; %if one of the paths is a direct link to a QTFrameServer.jar (because it ends with QTFrameServer.jar),
                    if exist(classpath{i}, 'file') == 2 %see if it actually exists
                        qtserveravailable = true; %if it does exist, then we found it,
                    else
                        javarmpath(classpath{i}); %if it doesn't actually exist, then it should be removed from the java path
                    end
                end
                if strfind(classpath{i}, 'QTJava.jar') == numel(classpath{i}) - numel('QTJava.jar') + 1;
                    if exist(classpath{i}, 'file') == 2
                        qtjavafound = true;
                    end
                end
                if strfind(classpath{i}, 'TIFFServer.jar') == numel(classpath{i}) - numel('TIFFServer.jar') + 1; %if one of the paths is a direct link to a TIFFServer.jar (because it ends with TIFFServer.jar),
                    if exist(classpath{i}, 'file') == 2 %see if it actually exists
                        tiffserveravailable = true; %if it does exist, then we found it,
                    else
                        javarmpath(classpath{i}); %if it doesn't actually exist, then it should be removed from the java path
                    end
                end
            end
            
            if ~qtserveravailable %if we still haven't found it,
                %then we check the Matlab paths
                pathsline = path;
                separator = pathsep;
                whereseparated = [0, strfind(pathsline, separator), numel(pathsline)+1];
                paths = [];
                for i=1:numel(whereseparated)-1
                    paths{i} = pathsline(whereseparated(i)+1:whereseparated(i+1)-1); %#ok<AGROW>
                end
                for i=1:numel(paths)
                    currentfullfile = fullfile(paths{i}, 'QTFrameServer.jar'); %add the filename to the path
                    if exist(currentfullfile, 'file') == 2 %and check if QTFrameServer.jar exists there
                        javaaddpath(currentfullfile); %if it does exist, then we found it,
                        qtserveravailable = true;
                        break;
                    end
                end
            end
            
            if ~tiffserveravailable %if we still haven't found it,
                %then we check the Matlab paths
                pathsline = path;
                separator = pathsep;
                whereseparated = [0, strfind(pathsline, separator), numel(pathsline)+1];
                paths = [];
                for i=1:numel(whereseparated)-1
                    paths{i} = pathsline(whereseparated(i)+1:whereseparated(i+1)-1); %#ok<AGROW>
                end
                for i=1:numel(paths)
                    currentfullfile = fullfile(paths{i}, 'TIFFServer.jar'); %add the filename to the path
                    if exist(currentfullfile, 'file') == 2 %and check if TIFFServer.jar exists there
                        javaaddpath(currentfullfile); %if it does exist, then we found it,
                        tiffserveravailable = true;
                        break;
                    end
                end
            end
            
            if ~qtjavafound %ispc && qtserveravailable && 
                qtjavalocations32 = {'C:\Program Files (x86)\QuickTime\QTSystem\QTJava.jar',...
                    'C:\Program Files (x86)\Java\jre9\lib\ext\QTJava.jar', 'C:\Program Files (x86)\Java\jre8\lib\ext\QTJava.jar',...
                    'C:\Program Files (x86)\Java\jre7\lib\ext\QTJava.jar', 'C:\Program Files (x86)\Java\jre6\lib\ext\QTJava.jar',...
                    'C:\Program Files (x86)\Java\jre5\lib\ext\QTJava.jar', 'C:\Program Files (x86)\Java\jre\lib\ext\QTJava.jar'};
                qtjavalocationsnormal = {'C:\Program Files\QuickTime\QTSystem\QTJava.jar',...
                    'C:\Program Files\Java\jre9\lib\ext\QTJava.jar', 'C:\Program Files\Java\jre8\lib\ext\QTJava.jar',...
                    'C:\Program Files\Java\jre7\lib\ext\QTJava.jar', 'C:\Program Files\Java\jre6\lib\ext\QTJava.jar',...
                    'C:\Program Files\Java\jre5\lib\ext\QTJava.jar', 'C:\Program Files\Java\jre\lib\ext\QTJava.jar'};
                if ~isempty(strfind(computer('arch'), '32')) %if Matlab sees 32-bit, we might still be on a 64-bit platform just with 32-bit Matlab, in which case loading a 64-bit version of QTJava may be problematic
                    qtjavalocations = [qtjavalocations32 qtjavalocationsnormal]; %so on 32-bit Matlab we first look in the 32-bit-specific folders, and only then in the normal/general folders
                else
                    qtjavalocations = [qtjavalocationsnormal qtjavalocations32]; %and on 64-bit Matlab we first look in the normal (64-bit) folders first, and only then in the 32-bit folders
                end
                for i=1:numel(qtjavalocations);
                    if exist(qtjavalocations{i}, 'file') == 2
                        javaaddpath(qtjavalocations{i});
                        break; %one QTJava should be enough
                    end
                end
            end
        
        catch, err = lasterror; %#ok<CTCH,LERR> %if some error occurred while fiddling with the QTFrameServer.jar file, then just don't use it %catch err would be nicer, but that doesn't work on older versions of Matlab
            fprintf(2, 'Warning: there was an unexpected error while trying to locate the QTFrameServer.jar file.\n');
            fprintf(2, '%s\n', err.message);
            qtserveravailable = false;
        end
    end
    
    function loadsettings(hobj, eventdata) %#ok<INUSD>
        if (exist([mfilename '-options.mat'], 'file') ~= 0)
            settingsdata = load([mfilename '-options.mat']);
            if isfield(settingsdata, 'directory')
                directory = settingsdata.directory;
            end
            if isfield(settingsdata, 'figureposition')
                set(handles.fig, 'OuterPosition', settingsdata.figureposition);
            end
            if isfield(settingsdata, 'directory')
                set(handles.folder,'String', settingsdata.directory);
            end
        %else
            %set(handles.fig, 'OuterPosition', get(0, 'Screensize')); %this doesn't seem to work in practice for some weird reason
        end
    end
    function savesettings(hobj,eventdata) %#ok<INUSD>
        closeqtobjects;
        closetiffobjects;
        settingsdata = struct;
        settingsdata.figureposition = get(handles.fig, 'OuterPosition');
        settingsdata.directory = get(handles.folder,'String');
        if ~isempty(settingsdata.figureposition)
            save([mfilename '-options.mat'], '-struct', 'settingsdata');
        end
        warning(oldwarningstate); %restore warning states as they were before zentracker was started
    end

    function updateonlynew(hobj, eventdata) %#ok<INUSD>
        onlynew = get(handles.onlynew, 'Value');
        updatefilelist;
    end

    function setsortby (hobj, eventdata) %#ok<INUSD>
        sortby = get(handles.sortby, 'Value');
        updatefilelist;
    end 

    function updatefilelist(hobj,eventdata) %#ok<INUSD>
        directory = get(handles.folder,'String');
        currentfiles = dir('*-ztdata.mat'); %always looking in the current directory
        
        if sortby == CONST_GUI_SORT_BYDATE_ASCENDING || sortby == CONST_GUI_SORT_BYDATE_DESCENDING
            if sortby == CONST_GUI_SORT_BYDATE_ASCENDING
                sortdirection = 'ascend';
            elseif sortby == CONST_GUI_SORT_BYDATE_DESCENDING
                sortdirection = 'descend';
            end
            dates = vertcat(currentfiles.datenum);
            [datessorted datessortedindex] = sort(dates, sortdirection);
            currentfiles = currentfiles(datessortedindex);
        end
        
        if onlynew
            waithide = waitbar(0, 'Hiding already analysed files...','Name','Checking files', 'CreateCancelBtn', 'delete(gcbf)');
            shouldbekept = true(1, numel(currentfiles));
            for i=1:numel(currentfiles)
                if ishandle(waithide)
                    waitbar(i/numel(currentfiles), waithide);
                else
                    break;
                end
                objectdetails = whos('-file', currentfiles(i).name, 'objects');
                if ~(objectdetails.bytes == 0 || numel(objectdetails.size) < 2 || objectdetails.size(1) == 0 || objectdetails.size(2) == 0) %if it isn't the case that the objects variable/structure is empty (i.e. if it's already analysed)
                    shouldbekept(i) = false;
                end
            end
            if ishandle(waithide) %if it wasn't cancelled
                delete(waithide)
                currentfiles = currentfiles(shouldbekept);
            else %if hiding was cancelled
                onlynew = false;
                set(handles.onlynew, 'Value', onlynew);
            end
        end
        
        filenames = {currentfiles.name};
        if isempty(filenames)
            set(handles.files,'String','');
        else
            set(handles.files,'String', filenames);
            set(handles.files,'Value', 1);
        end
        selectfile;
    end

    % Select a new directory graphically
    function browse(hobj,eventdata) %#ok<INUSD>
        newdirectory = uigetdir(directory,'Select data folder');
        if newdirectory ~= 0
            directory = newdirectory;
            set(handles.folder,'String',directory);
        end
    end

    function selectfile(hobj, eventdata) %#ok<INUSD>
        allstrings = get(handles.files,'String');
        if ~isempty(allstrings)
            selectedfiles = allstrings(get(handles.files,'Value'));
        else
            selectedfiles = [];
        end
    end

    function analyse(hobj, eventdata) %#ok<INUSD>
        
        waitoverall = waitbar(0, sprintf('%d/%d', 1, numel(selectedfiles)),'Name','Overall progress', 'CreateCancelBtn', 'delete(gcbf)');
        
        for currentmovie = 1:numel(selectedfiles)
            
            try
            
                if ishandle(waitoverall) > 0
                    waitbar(currentmovie/numel(selectedfiles), waitoverall, sprintf('%d/%d', currentmovie, numel(selectedfiles)));
                else
                    break;
                end

                ztdata = load(selectedfiles{currentmovie}); %loading mat file from the current directory

                %clearing cache
                cachedframe = [];
                cachedindex = NaN;
                moviereaderobjects = struct([]);

                moviefiles = ztdata.selectedfiles;
                movieindicator = ztdata.movieindicator;
                frameindicator = ztdata.frameindicator;
                lastframe = ztdata.lastframe;
                framerate = ztdata.framerate;

                if isfield(ztdata, 'detectionarea')
                    detectionarea = ztdata.detectionarea;
                elseif isfield(ztdata, 'thresholdingarea')
                    detectionarea = ztdata.thresholdingarea;
                else
                    fprintf(2, 'Warning: detection area appears undefined for movie %s . Skipping this movie!\n', selectedfiles{currentmovie});
                    continue;
                end

                if isfield(ztdata, 'measurementarea')
                    measurementarea = ztdata.measurementarea;
                elseif isfield(ztdata, 'validarea')
                    measurementarea = ztdata.validarea;
                else
                    fprintf(2, 'Warning: measurement area appears undefined for movie %s . Assuming it is the same as the detection area...\n', selectedfiles{currentmovie});
                    measurementarea = detectionarea;
                end

                scalingfactor = ztdata.scalingfactor;
                validspeedmin = ztdata.validspeedmin;
                validspeedmin = ztdata.validspeedmax;
                validlengthmin = ztdata.validlengthmin;
                validlengthmax = ztdata.validlengthmax;
                validwidthmin = ztdata.validwidthmin;
                validwidthmax = ztdata.validwidthmax;
                validareamin = ztdata.validareamin;
                validareamax = ztdata.validareamax;
                validperimetermin = ztdata.validperimetermin;
                validperimetermax = ztdata.validperimetermax;
                if isfield(ztdata, 'valideccentricitymin')
                    valideccentricitymin = ztdata.valideccentricitymin;
                elseif isfield(ztdata, 'validroundnessmin')
                    valideccentricitymin = ztdata.validroundnessmin;
                else
                    valideccentricitymin = 0;
                end
                if isfield(ztdata, 'valideccentricitymax')
                    valideccentricitymax = ztdata.valideccentricitymax;
                elseif isfield(ztdata, 'validroundnessmax')
                    valideccentricitymax = ztdata.validroundnessmax;
                else
                    valideccentricitymax = 0;
                end

                validdurationcheckstyle = ztdata.validdurationcheckstyle;
                validdurationminimum = ztdata.validdurationminimum;

                if isfield(ztdata, 'gradnormmatrix')
                    gradnormmatrix = ztdata.gradnormmatrix;
                else
                    gradnormmatrix = [];
                end
                if isfield(ztdata, 'gradnorm')
                    gradnorm = ztdata.gradnorm;
                else
                    gradnorm = false;
                end
                if isfield(ztdata, 'timenorm')
                    timenorm = ztdata.timenorm;
                else
                    timenorm = false;
                end

                thresholdsizemin = ztdata.thresholdsizemin;
                thresholdsizemax = ztdata.thresholdsizemax;
                thresholdintensity = ztdata.thresholdintensity;
                thresholdspeedmax = ztdata.thresholdspeedmax;
                pixelmax = ztdata.pixelmax;
                
                if isfield(ztdata, 'saveversion') && strcmpi(earlierversion(ztdata.saveversion, '2.7.3'), 'earlier')
                    fprintf('Warning: the detection parameters available from the analysis data for movie %s appear to be from an older version. The object detection size range is specified as %f - %f.', selectedfiles{currentmovie}, thresholdsizemin, thresholdsizemax);
                    thresholdsizemin = thresholdsizemin * scalingfactor^2;
                    thresholdsizemax = thresholdsizemax * scalingfactor^2;
                    fprintf(' This is assumed to be in pixels. Attempting to compensate by converting to um^2, which results in a range of %f - %f.', thresholdsizemin, thresholdsizemax);
                    if get(handles.doduration, 'Value') %only bother with validdurationminimum if we are going to be checking for it
                        fprintf(' The minimum valid duration is specified as %f%f.', validdurationminimum);
                        validdurationminimum = validdurationminimum/framerate;
                        fprintf(' This is assumed to be in frames. Attempting to compensate by converting to seconds, which results in a minimum of %f .', validdurationminimum);
                    end
                    fprintf('\n');
                end

                if isinf(thresholdspeedmax) || isnan(thresholdspeedmax)
                    fprintf('Warning: maximum speed threshold appears to be undefined for movie %s . This may result in inaccurate tracking. It is strongly recommended to set a max speed threshold, perhaps around 3x the expected mean speed of a fast object (e.g. 600 um/s threshold for C. elegans).\n', selectedfiles{currentmovie});
                end

                %only bother with opening the movie if we need to actually track
                if get(handles.dotrack, 'Value')
                    objects = [];
                    %check if the movie files exist
                    allexist = true;
                    for moviecheckindex=1:numel(moviefiles)
                        moviecheckfilename = fullfile(directory,moviefiles{moviecheckindex});
                        if exist(moviecheckfilename, 'file') ~= 2
                            allexist = false;
                            break;
                        end
                    end
                    if ~allexist
                        fprintf(2, 'Warning: the movie file %s was not found. Skipping analysis of this movie!\n', moviecheckfilename);
                        continue; %skipping to the next movie(s) to analyse
                    end

                    try
                        readmovie;
                    catch %#ok<CTCH>
                        fprintf(2, 'Warning: there was a problem reading movie %s . Skipping analysis of this movie!\n', selectedfiles{currentmovie});
                        continue;
                    end
                else %if not tracking, we need to get the objects structure from the savefile
                    objects = ztdata.objects;
                end

                clear ztdata; %now that we gathered all required data from the loaded savefile, unload them from memory, which also makes sure that we don't accidentally refer to them

                waitbarfps = 20; %CHANGEME: should be adjustable somehow

                waitfile = waitbar(0, selectedfiles{currentmovie}, 'Name', 'Processing current file', 'CreateCancelBtn', 'delete(gcbf)');
                %now to set the Interpreter of the title to 'none' in a very roundabout way because waitbar itself doesn't have an 'Interpreter' property...
                waitfilechildren = get(waitfile, 'Children');
                waitfilechildrentitle = get(waitfilechildren(1), 'Title');
                set(waitfilechildrentitle, 'Interpreter', 'none');
                drawnow;

                if get(handles.dotrack, 'Value') %only track if asked to

                    if ~isnan(thresholdspeedmax) && thresholdspeedmax > 0
                        distance2threshold = (thresholdspeedmax/scalingfactor/framerate)^2; %the threshold on (the square of) the centroid-displacements, in terms of pixels per frames
                    else
                        distance2threshold = Inf;
                    end

                    firstobject = true;            

                    for i=1:lastframe

                        if ishandle(waitfile) > 0
                            if mod(i, waitbarfps) == 0
                                waitbar(i/lastframe, waitfile);
                            end
                        else
                            break;
                        end

                        originalimage = readframe(i);
                        thresholdedimage = thresholdimage(originalimage);
                        labelledimage = bwlabel(thresholdedimage);

                        if verLessThan('matlab', '7.8')
                            thresholdedregions = regionprops(labelledimage,'Area'); %#ok<MRPBW>
                        else
                            thresholdedregions = regionprops(thresholdedimage,'Area');
                        end

                        allregionareas = vertcat(thresholdedregions.Area);
                        goodregions = find(allregionareas >= thresholdsizemin/scalingfactor^2 & allregionareas <= thresholdsizemax/scalingfactor^2);
                        thresholdedimage = ismember(labelledimage, goodregions); %keeping only the appropriately sized regions

                        if verLessThan('matlab', '7.8')
                            labelledimage = bwlabel(thresholdedimage);
                            thresholdedregions = regionprops(labelledimage,'Centroid','Area','MinorAxisLength','MajorAxisLength','Perimeter','Eccentricity','Solidity'); %#ok<MRPBW>
                        else
                            thresholdedregions = regionprops(thresholdedimage,'Centroid','Area','MinorAxisLength','MajorAxisLength','Perimeter','Eccentricity','Solidity');
                        end

                        if i>1 && ~firstobject
                            costmatrix = Inf(numel(thresholdedregions), numel(lastregions));
                            for j=1:numel(thresholdedregions)
                                for k=1:numel(lastregions)
                                    distance2 = (lastregions(k).x-thresholdedregions(j).Centroid(1))^2 + (lastregions(k).y-thresholdedregions(j).Centroid(2))^2;
                                    if distance2 <= distance2threshold
                                        costmatrix(j, k) = distance2;
                                    end
                                end
                            end

                            assignment = assignmentoptimal(costmatrix); %Solving the across-frame assignment problem using the Hungarian algorithm
                        else
                            assignment = zeros(1, numel(thresholdedregions));
                        end

                        %assert(numel(thresholdedregions) == numel(assignment));

                        for j=1:numel(thresholdedregions)
                            if assignment(j) ~= 0

                                objects(lastregions(assignment(j)).id).frame(end+1) = i;
                                objects(lastregions(assignment(j)).id).time(end+1) = converttotime(i);
                                objects(lastregions(assignment(j)).id).x(end+1) = thresholdedregions(j).Centroid(1);
                                objects(lastregions(assignment(j)).id).y(end+1) = thresholdedregions(j).Centroid(2);
                                objects(lastregions(assignment(j)).id).length(end+1) = thresholdedregions(j).MajorAxisLength;
                                objects(lastregions(assignment(j)).id).width(end+1) = thresholdedregions(j).MinorAxisLength;
                                objects(lastregions(assignment(j)).id).area(end+1) = thresholdedregions(j).Area;
                                objects(lastregions(assignment(j)).id).perimeter(end+1) = thresholdedregions(j).Perimeter;
                                objects(lastregions(assignment(j)).id).eccentricity(end+1) = thresholdedregions(j).Eccentricity;
                                objects(lastregions(assignment(j)).id).solidity(end+1) = thresholdedregions(j).Solidity;
                                objects(lastregions(assignment(j)).id).compactness(end+1) = thresholdedregions(j).Perimeter.^2./thresholdedregions(j).Area;
                                objects(lastregions(assignment(j)).id).speed(end+1) = realsqrt(costmatrix(j, assignment(j))) * framerate; %realsqrt of the costmatrix gives the instantaneous displacement across frames; multiplying it by the framerate is equivalent to dividing by the time-difference between successive frames
                                objects(lastregions(assignment(j)).id).behaviour(end+1) = CONST_BEHAVIOUR_UNKNOWN;
                                objects(lastregions(assignment(j)).id).duration = objects(lastregions(assignment(j)).id).duration + 1;
                                thresholdedregions(j).id = lastregions(assignment(j)).id;

                            else

                                if firstobject
                                    objects(1).frame(1) = i;
                                    firstobject = false;
                                else
                                    objects(end+1).frame(1) = i; %#ok<AGROW>
                                end

                                objects(end).time(1) = converttotime(i);
                                objects(end).x(1) = thresholdedregions(j).Centroid(1);
                                objects(end).y(1) = thresholdedregions(j).Centroid(2);
                                objects(end).length(1) = thresholdedregions(j).MajorAxisLength;
                                objects(end).width(1) = thresholdedregions(j).MinorAxisLength;
                                objects(end).area(1) = thresholdedregions(j).Area;
                                objects(end).perimeter(1) = thresholdedregions(j).Perimeter;
                                objects(end).eccentricity(1) = thresholdedregions(j).Eccentricity;
                                objects(end).solidity(1) = thresholdedregions(j).Solidity;
                                objects(end).compactness(1) = thresholdedregions(j).Perimeter.^2./thresholdedregions(j).Area;
                                objects(end).speed(1) = NaN;
                                objects(end).behaviour(1) = CONST_BEHAVIOUR_UNKNOWN;
                                objects(end).duration = 1;
                                thresholdedregions(j).id = numel(objects);

                            end
                        end

                        lastregions = struct('x', [], 'y', [], 'id', []);
                        for j=1:numel(thresholdedregions)
                            lastregions(j).x = thresholdedregions(j).Centroid(1);
                            lastregions(j).y = thresholdedregions(j).Centroid(2);
                            lastregions(j).id = thresholdedregions(j).id;
                        end

                    end

                    for i=1:numel(objects)
                        objects(i).directionchange = NaN(1, objects(i).duration);
                        lastdirection = NaN;
                        for j=2:objects(i).duration
                            currentdirection = getabsoluteangle(objects(i).x(j-1), objects(i).y(j-1), objects(i).x(j), objects(i).y(j));
                            objects(i).directionchange(j) = angledifference(lastdirection, currentdirection);
                            lastdirection = currentdirection;
                        end
                    end

                end

                closeqtobjects;
                closetiffobjects;

                if get(handles.dovalidity, 'Value')
                    %validity check
                    for i=1:numel(objects)
                        for j=1:objects(i).duration
                            if invaliditycheckframe(i, j)
                                objects(i).behaviour(j) = CONST_BEHAVIOUR_INVALID;
                            elseif objects(i).behaviour(j) == CONST_BEHAVIOUR_INVALID
                                objects(i).behaviour(j) = CONST_BEHAVIOUR_UNKNOWN;
                            end
                        end
                    end
                end

                if get(handles.doduration, 'Value')
                    %valid duration check
                    i=1;
                    while i<=numel(objects) %I want to be able to move the index one step earlier in certain cases, and a for is less flexible in that respect
                        if objects(i).duration < round(validdurationminimum*framerate)
                            if validdurationcheckstyle == 1 %mark as invalid
                                objects(i).behaviour = ones(1, objects(i).duration) * CONST_BEHAVIOUR_INVALID;
                            elseif validdurationcheckstyle == 2 %delete
                                %I want to keep the order of worms in the sense that worms detected earlier should have smaller id numbers, so I'm just going to simply move all objects one step earlier, delete the last object, and recheck the object with the current index
                                for j=i:numel(objects)-1
                                    objects(j) = objects(j+1);
                                end
                                objects = objects(1:end-1);
                                i = i - 1;
                            end
                        end
                        i = i + 1;
                    end
                end

                %recalculatemeanperimeter
                if ~isempty(objects)
                    meanindividualperimeter = NaN(numel(objects), 1);
                    for i=1:numel(objects)
                        whichindicesareok = ~isnan(objects(i).perimeter) & objects(i).behaviour ~= CONST_BEHAVIOUR_INVALID;
                        if any(whichindicesareok)
                            meanindividualperimeter(i) = mean(objects(i).perimeter(whichindicesareok));
                        else
                            meanindividualperimeter(i) = NaN;
                        end
                    end
                    if any(~isnan(meanindividualperimeter))
                        meanperimeter = mean(meanindividualperimeter(~isnan(meanindividualperimeter))); %#ok<SETNU> %we will save this into the datafile
                    else
                        meanperimeter = NaN;
                    end
                else
                    meanperimeter = NaN;
                end

                if ishandle(waitfile)
                    close(waitfile);
                end

                save(selectedfiles{currentmovie}, 'objects', 'meanperimeter', '-append');
                
            catch, err = lasterror; %#ok<CTCH,LERR> %making sure that an unexpected error occurring during the analysis of one of the movies does not prevent the rest of the movies in the batch from being analysed %catch err would be nicer, but that doesn't work on older versions of Matlab
                fprintf(2, 'An unexpected error occurred during the analysis of movie %s .\n', selectedfiles{currentmovie});
                fprintf(2, err.message);
                fprintf(2, 'Skipping this movie and continuing the analysis of other movies...\n');
                if ishandle(waitfile)
                    close(waitfile);
                end
            end
            
        end
        
        if ishandle(waitoverall) > 0
            close(waitoverall);
            fprintf('Finished successfully.\n');
        end
    end

    function thresholded = thresholdimage (imagetothreshold)
        
        if numel(size(imagetothreshold)) == 3 && size(imagetothreshold, 3) == 3
            imagetothreshold = rgb2gray(imagetothreshold);
        end
        
        thresholded = imagetothreshold < thresholdintensity; %im2bw has trouble with floating-point intensity values, so we'll just threshold directly
        thresholded(~detectionarea) = false;
        thresholded = imerode(imdilate(thresholded, disklike), disklike);

    end

    function readmovie
        
        successfullyread = false;
        
        for i=1:numel(moviefiles)
            
            currentfullfile = fullfile(directory, moviefiles{i});
        
            if strcmpi(moviefiles{i}(end-3:end), '.tif') || strcmpi(moviefiles{i}(end-4:end), '.tiff')
                if ~tiffserveravailable
                    fprintf('Warning: TIFFServer.jar was not found in the Matlab paths. This will probably result in the tiff file not being read correctly. Attempting to proceed anyway for now, but ideally, make sure that TIFFServer.jar is available.\n');
                else
                    if ~successfullyread
                        try
                            tiffservers(end+1).server = util.TIFFServer; %#ok<AGROW> %having an array of objects causes problems because by declaring it at the start of the program (to give it a greater scope) produces an array of doubles, which is incompatible with these objects. so instead we'll declare a structure, each element of which can have an object
                            tiffservers(end).server.open(currentfullfile);
                            tiffservers(end).filename = moviefiles{i};
                            %we'll delay setting totalduration until the user confirms the framerate, because if user changes the framerate, that would make the apparent totalduration different (because what we know for sure is the number of frames, not the duration in seconds
                            successfullyread = true;
                            fprintf('Movie %s opened successfully using TIFFServer.\n', moviefiles{i});
                        catch, err = lasterror; %#ok<CTCH,LERR> %catch err would be nicer, but that doesn't work on older versions of Matlab
                            if ~isempty(tiffservers) && isfield(tiffservers(end), 'server') && (~isfield(tiffservers(end), 'filename') || strcmp(tiffservers(end).filename, moviefiles{i})) %if we've managed to create the TIFFServer for this file, but still had an error,
                                try %try to close the stream, but don't worry if closing fails (because closing may fail because opening failed in the first place)
                                    tiffservers(end).server.close;
                                catch %#ok<CTCH>
                                end
                                tiffservers = tiffservers(1:end-1); %we'll remove this TIFFServer instance that produced the error
                                fprintf('Opening the movie %s using TIFFServer failed.\n', moviefiles{i});
                                fprintf('%s\n', err.message);
                                fprintf('Attempting to open the movie using another method...\n');
                            end
                        end
                    end
                end
            end

            if ~(ispc && strcmpi(moviefiles{i}(end-3:end), '.mov')) %reading of quicktime movies is not supported on Windows, and in my experience can sometimes cause the wrong frames to be displayed (when not all frames are cached, which we cannot ensure), so we'll fall back to other options, probably mmread
                if ~successfullyread
                    try
                        moviereaderobjects(end+1).reader = VideoReader(currentfullfile); %#ok<AGROW> %having an array of objects causes problems because by declaring it at the start of the program (to give it a greater scope) produces an array of doubles, which is incompatible with these objects. so instead we'll declare a structure, each element of which can have an object
                        successfullyread = true;
                        fprintf('Movie %s opened successfully using VideoReader.\n', moviefiles{i});
                    catch %#ok<CTCH>
                        if ~isempty(moviereaderobjects) && isfield(moviereaderobjects(end), 'reader') && strcmp(get(moviereaderobjects(end).reader, 'Name'), moviefiles{i}) %if we've managed to create the moviereaderobject for this file, but still had an error,
                            moviereaderobjects = moviereaderobjects(1:end-1); %we'll remove this moviereaderobject that produced an error
                        end
                    end
                end

                if ~successfullyread
                    try
                        lastwarn('');
                        warning('off', 'MATLAB:mmreader:unknownNumFrames'); %we'll get the number of frames ourselves anyway, so this warning is not really relevant
                        moviereaderobjects(end+1).reader = mmreader(currentfullfile);  %#ok<TNMLP,AGROW>
                        warning('on', 'MATLAB:mmreader:unknownNumFrames');
                        if ~isempty(lastwarn) && ~cachemovie %mmreader doesn't understand the number of frames, so the wrong frames may be displayed when we try to read single frames using it, but if we're caching the whole movie at once with mmreader, then apparently it's fine even if it doesn't understand the number of frames
                            error('MATLAB:mmreader:unknownNumFrames', lastwarn);
                        end
                        successfullyread = true;
                        fprintf('Movie %s opened successfully using mmreader.\n', moviefiles{i});
                    catch %#ok<CTCH>
                        if ~isempty(moviereaderobjects) && isfield(moviereaderobjects(end), 'reader') && strcmp(get(moviereaderobjects(end).reader, 'Name'), moviefiles{i}) %if we've managed to create the moviereaderobject for this file, but still had an error,
                            moviereaderobjects = moviereaderobjects(1:end-1); %we'll remove this moviereaderobject that produced an error
                        end
                    end
                end
            end

            triedaviread = false;
            triedmmread = false;
            triedqtreader = false;
            delayforqtreader = false;
            if strcmpi(moviefiles{i}(end-3:end), '.mov') %if the current file is a mov, we'll try Robin's QTFrameServer first before the other options, otherwise (for non-movs) it's the last option
                delayforqtreader = true;
            end

            while ~ (successfullyread || (triedaviread && triedmmread && triedqtreader))

                clear video;
                if ~successfullyread && ~delayforqtreader && ~triedaviread
                    try
                        triedaviread = true;
                        video = aviread(currentfullfile, 1); %#ok<NASGU> %attempting to actually read a frame to test if aviread works
                        successfullyread = true;
                        avireadworks = true;
                        fprintf('Movie %s opened successfully using aviread.\n', moviefiles{i});
                    catch %#ok<CTCH>
                        clear video;
                        avireadworks = false;
                    end
                end

                if ~successfullyread && ~delayforqtreader && ~triedmmread
                    try
                        triedmmread = true;                       
                        [video, audio] = mmread(currentfullfile, 1); %#ok<NASGU>
                        successfullyread = true;
                        fprintf('Movie %s opened successfully using mmread.\n', moviefiles{i});
                    catch %#ok<CTCH>
                        clear video;
                    end
                end

                delayforqtreader = false;
                if ~successfullyread && qtserveravailable && ~triedqtreader
                    try
                        triedqtreader = true;
                        qtreaders(end+1).server = util.QTFrameServer(currentfullfile); %#ok<AGROW> %having an array of objects causes problems because by declaring it at the start of the program (to give it a greater scope) produces an array of doubles, which is incompatible with these objects. so instead we'll declare a structure, each element of which can have an object
                        qtreaders(end).filename = moviefiles{i};
                        successfullyread = true;
                        fprintf('Movie %s opened successfully using QTFrameServer.\n', moviefiles{i});
                    catch %#ok<CTCH>
                        if ~isempty(qtreaders) && isfield(qtreaders(end), 'server') && (~isfield(qtreaders(end), 'filename') || strcmp(qtreaders(end).filename, moviefiles{i})) %if we've managed to create the QTFrameServer for this file, but still had an error,
                            try %try to close the stream, but don't worry if closing fails (because closing may fail because opening failed in the first place)
                                qtreaders(end).server.close;
                            catch %#ok<CTCH>
                            end
                            qtreaders = qtreaders(1:end-1); %we'll remove this QTFrameServer instance that produced the error
                        end
                    end
                end

            end

            if ~successfullyread && triedaviread && triedmmread && triedqtreader
                error('Could not read the movie by any available method.');
            end
        end
        
    end

    function cdata = readframe(whichframe) %reads the from the appropriate frame of the appropriate movie
        if whichframe ~= cachedindex %what's requested isn't already the currently cached frame, we'll need to get it
            if isstruct(moviecache) && numel(moviecache) >= whichframe && isfield(moviecache, 'data') && ~isempty(moviecache(whichframe).data) %if we have the entire movie cached, then we just grab the frame
                currentframe = moviecache(whichframe).data;
            else %otherwise we'll need to actually read it from a file
                successfullyread = false;
                if ~isempty(tiffservers)
                    currenttiffobject = 0;
                    for i=1:numel(tiffservers)
                        if strcmp(moviefiles{movieindicator(whichframe)}, tiffservers(i).filename)
                            currenttiffobject = i;
                            break;
                        end
                    end
                    if currenttiffobject ~= 0
                        try
                            currentframe = tiffservers(currenttiffobject).server.getImage(frameindicator(whichframe));
                            successfullyread = true;
                        catch %#ok<CTCH>
                            if ~readerfailuredisplayed(movieindicator(whichframe))
                                readerfailuredisplayed(movieindicator(whichframe)) = true;
                                fprintf(2, 'Warning: %s could not be read using TIFFServer. This is unexpected because the movie was opened successfully using this method earlier. Trying fallback options...\n', moviefiles{movieindicator(whichframe)});
                            end
                        end
                    end
                end
                if ~isempty(qtreaders)
                    currentqtobject = 0;
                    for i=1:numel(qtreaders)
                        if strcmp(moviefiles{movieindicator(whichframe)}, qtreaders(i).filename)
                            currentqtobject = i;
                            break;
                        end
                    end
                    if currentqtobject ~= 0
                        try
                            currentframe = uint8(qtreaders(currentqtobject).server.getBW(frameindicator(whichframe)));
                            successfullyread = true;
                        catch %#ok<CTCH>
                            if ~readerfailuredisplayed(movieindicator(whichframe))
                                readerfailuredisplayed(movieindicator(whichframe)) = true;
                                fprintf(2, 'Warning: %s could not be read using QTFrameServer. This is unexpected because the movie was opened successfully using this method earlier. Trying fallback options...\n', moviefiles{movieindicator(whichframe)});
                            end
                        end
                    end
                end
                if ~isempty(moviereaderobjects) %only try to read with the newer method (VideoReader or mmreader objects) if we've already managed to open the file with this method
                    currentreaderobject = 0;
                    for i=1:numel(moviereaderobjects) %trying to see if we've already set up a movie reader object for this file
                        if strcmp(moviefiles{movieindicator(whichframe)}, get(moviereaderobjects(i).reader, 'Name'))
                            currentreaderobject = i;
                            break;
                        end
                    end
                    if currentreaderobject ~= 0 %if we've managed to find sort of movie reader object, then read the video
                        try
                            currentframe = read(moviereaderobjects(currentreaderobject).reader, frameindicator(whichframe));
                            successfullyread = true;
                        catch %#ok<CTCH>
                            if ~readerfailuredisplayed(movieindicator(whichframe))
                                readerfailuredisplayed(movieindicator(whichframe)) = true;
                                fprintf(2, 'Warning: %s could not be read using a reader object. This is unexpected because the movie was opened successfully using this method earlier. Trying fallback options...\n', moviefiles{movieindicator(whichframe)});
                            end
                        end
                    end
                end
                if ~successfullyread && avireadworks %if we haven't managed to read the frame yet, fall back to aviread, if possible
                    video = aviread(fullfile(directory,moviefiles{movieindicator(whichframe)}), frameindicator(whichframe));
                    currentframe = video.cdata;
                    successfullyread = true;
                end
                if ~successfullyread %if we still haven't managed to read the frame, fall back to mmread
                    [video, audio] = mmread(fullfile(directory,moviefiles{movieindicator(whichframe)}), frameindicator(whichframe)); %#ok<NASGU>
                    currentframe = video.frames(1).cdata;
                end
            end
            
            %Converting RGB values to grayscale
            if numel(size(currentframe)) >= 3 && size(currentframe, 3) == 3
                currentframe = rgb2gray(currentframe);
            end
            %Matlab cannot display uint32 or int32 class RGB images (and we will eventually make RGB images based on these data), so we'll have to convert them
            if strcmp(class(currentframe), 'uint32') || strcmp(class(currentframe), 'int32')
                currentframe = uint16(currentframe);
            end
            
            cachedframe = currentframe;
            if gradnorm && ~isempty(gradnormmatrix) && ~any(isnan(gradnormmatrix(:)))
                %cachedframe = double(cachedframe)./gradnormmatrix;
                imageclass = class(cachedframe); %preserving original image class
                if timenorm %if we're going to do time-normalization anyway (which will result in double class images), don't needlessly truncate the dynamic range by casting the matrix as anything other than double
                    imageclass = 'double';
                end
                cachedframe = cast(double(cachedframe)./gradnormmatrix, imageclass);
            end
            if timenorm
                
                cachedframe = double(cachedframe);
                
                if any(detectionarea(:))
                    pixelstouse = cachedframe(detectionarea);
                else
                    pixelstouse = cachedframe(:);
                end
                
                %cachedframe = double(cachedframe)./timenormvector(whichframe);
                
                cachedframe = cachedframe-mean(pixelstouse);
                cachedframe = cachedframe/std(pixelstouse)*(1/20);
                cachedframe = cachedframe+0.5;
                
                cachedframe(cachedframe < 0.0) = 0.0;
                cachedframe(cachedframe > 1.0) = 1.0;
                
                cachedframe = cachedframe * pixelmax;
            end
            cachedindex = whichframe;
        end
        cdata = cachedframe;
    end

    function returnintime = converttotime (frame)
        returnintime = (frame-1)/framerate;
    end

    function angleinradians = getabsoluteangle(xold, yold, xnew, ynew)
        angleinradians = atan2(ynew-yold, xnew-xold);
    end

    %gives the (signed) change in (shorter) angle between anglenew and angleold (in radians)
    function difference = angledifference(angleold, anglenew) 
        difference = anglenew - angleold;
        %checking if moving one of the angles by a full circle would bring the two closer in terms of absolute angle difference. If so, we'll use that (signed) value. This is to work around the issue of pi-epsilon being very near to -pi+epsilon (but not in terms of naive angle difference).
        difference2 = (anglenew + 2*pi) - angleold;
        difference3 = anglenew - (angleold + 2*pi);
        if abs(difference2) < abs(difference)
            difference = difference2;
        end
        if abs(difference3) < abs(difference)
            difference = difference3;
        end
    end

    function itisearlier = earlierversion (isthisearlier, thanthis)
        %kind of like the built-in verlessthan function, except for zentracker
        %return values are 'earlier', 'later', 'same', 'unknown'
        
        string1 = isthisearlier;
        string2 = thanthis;
        
        wherepre1 = strfind(lower(string1), 'pre');
        wherepre2 = strfind(lower(string2), 'pre');
        
        delimiters1 = find(string1 < '0' | string1 > '9');
        delimiters2 = find(string2 < '0' | string2 > '9');
        
        %adding dummy delimiters to the beginning and end of the string so as to be able to process the entire string just by looking at string between delimiters
        delimiters1 = [0 delimiters1 numel(string1)+1];
        delimiters2 = [0 delimiters2 numel(string2)+1];
        
        numbers1 = [];
        numbers2 = [];
        
        for i=1:numel(delimiters1)-1
            if ismember(delimiters1(i), wherepre1)
                numbers1(end+1) = -2; %#ok<AGROW> %pre denotes a pre-release version (i.e. earlier than an unnumbered version ("-1"), which is earlier than any numbered version (0>)
            else
                currentstring = string1(delimiters1(i)+1:delimiters1(i+1)-1);
                if ~isempty(currentstring) %when encountering more than one consecutive delimiters (e.g. in "2.7.0pre3", "pre" counts are three consecutive delimiters, just continue after the last consecutive delimiter
                    currentnumber = str2double(currentstring);
                    if ~isnan(currentnumber)
                        numbers1(end+1) = currentnumber; %#ok<AGROW>
                    else
                        itisearlier = 'unknown';
                        return;
                    end
                end
            end
        end
        
        for i=1:numel(delimiters2)-1
            if ismember(delimiters2(i), wherepre2)
                numbers2(end+1) = -2; %#ok<AGROW> %pre denotes a pre-release version
            else
                currentstring = string2(delimiters2(i)+1:delimiters2(i+1)-1);
                if ~isempty(currentstring) %when encountering more than one consecutive delimiters (e.g. in "2.7.0pre3", "pre" counts are three consecutive delimiters, just continue after the last consecutive delimiter
                    currentnumber = str2double(currentstring);
                    if ~isnan(currentnumber)
                        numbers2(end+1) = currentnumber; %#ok<AGROW>
                    else
                        itisearlier = 'unknown';
                        return;
                    end
                end
            end
        end
        
        if isempty(numbers1) || isempty(numbers2)
            itisearlier = 'unknown';
            return;
        end
        
        %e.g. 2.7 is an earlier version than 2.7.5, so to make them comparable, we'll add a "-1" (later than pre-release (-2), but earlier than any numbered version) as the last number(s) to the shorter version number, i.e. turning [2, 7] into [2, 7, -2]
        if numel(numbers1) < numel(numbers2)
            numbers1(end+1:numel(numbers2)) = -1;
        elseif numel(numbers2) < numel(numbers1)
            numbers2(end+1:numel(numbers1)) = -1;
        end
        
        earlier1 = find(numbers1 < numbers2, 1, 'first');
        later1 = find(numbers1 > numbers2, 1, 'first');
        
        if isempty(earlier1)
            earlier1 = Inf;
        end
        if isempty(later1)
            later1 = Inf;
        end
        
        if earlier1 < later1
            itisearlier = 'earlier';
            return;
        elseif later1 < earlier1
            itisearlier = 'later';
            return;
        else
            %we haven't found any difference, therefore they're considered the same
            itisearlier = 'same';
        end
        
    end

    function isitinvalid = invaliditycheckframe (objectindex, frameindex)
        
        isitinvalid = false;
        
        if ~measurementarea(round(objects(objectindex).y(frameindex)), round(objects(objectindex).x(frameindex))) ...
        || (validspeedmin > 0 && objects(objectindex).speed(frameindex) < validspeedmin/scalingfactor) ...
        || (validspeedmax > 0 && objects(objectindex).speed(frameindex) > validspeedmax/scalingfactor) ...
        || (validlengthmin > 0 && objects(objectindex).length(frameindex) < validlengthmin/scalingfactor) ...
        || (validlengthmax > 0 && objects(objectindex).length(frameindex) > validlengthmax/scalingfactor) ...
        || (validwidthmin > 0 && objects(objectindex).width(frameindex) < validwidthmin/scalingfactor) ...
        || (validwidthmax > 0 && objects(objectindex).width(frameindex) > validwidthmax/scalingfactor) ...
        || (validareamin > 0 && objects(objectindex).area(frameindex) < validareamin/scalingfactor/scalingfactor) ...
        || (validareamax > 0 && objects(objectindex).area(frameindex) > validareamax/scalingfactor/scalingfactor) ...
        || (validperimetermin > 0 && objects(objectindex).perimeter(frameindex) < validperimetermin/scalingfactor) ...
        || (validperimetermax > 0 && objects(objectindex).perimeter(frameindex) > validperimetermax/scalingfactor) ...
        || (valideccentricitymin > 0 && objects(objectindex).eccentricity(frameindex) < valideccentricitymin) ...
        || (valideccentricitymax > 0 && objects(objectindex).eccentricity(frameindex) > valideccentricitymax)
                isitinvalid = true;
        end
        
    end

    function closeqtobjects (hobj,eventdata) %#ok<INUSD>
        for i=1:numel(qtreaders)
            try
                qtreaders(i).server.close;
            catch, err = lasterror; %#ok<LERR,CTCH> %catch err would be nicer, but that doesn't work on older versions of Matlab
                fprintf(2, 'Warning: could not close the QTFrameServer object appropriately for ');
                if isfield(qtreaders(i), 'filename')
                    fprintf(2, 'file %s\n', qtreaders(i).filename);
                else
                    fprintf(2, 'movie number %d\n', i);
                end
                fprintf(2, '%s\n', err.message);
            end
        end
        qtreaders = struct([]);
    end

    function closetiffobjects (hobj, eventdata) %#ok<INUSD>
        for i=1:numel(tiffservers)
            try
                tiffservers(i).server.close;
            catch, err = lasterror; %#ok<LERR,CTCH> %catch err would be nicer, but that doesn't work on older versions of Matlab
                fprintf(2, 'Warning: could not close the TIFFServer object appropriately for ');
                if isfield(tiffservers(i), 'filename')
                    fprintf(2, 'file %s\n', tiffservers(i).filename);
                else
                    fprintf(2, 'movie number %d\n', i);
                end
                fprintf(2, '%s\n', err.message);
            end
        end
        tiffservers = struct([]);
    end
    
end