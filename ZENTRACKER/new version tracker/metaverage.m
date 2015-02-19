%added: spectral density extraction and plotting
%fixed: arcsine transformation
%removed: read variance option
%improved: for movies for which the framerate could not be obtained, it will ask the user for input if it's required for binning
%improved: NaN values appearing as constituents in a bin get disregarded instead of setting the value of the entire bin to NaN
%improved: binning now works for ratio data

function metaverage

    version = '2.21';
    
    set(0,'DefaultAxesLineStyleOrder',{'-',':','--','-.'}); %When plotting results, cycle through different line styles in addition to the different colours so that more combinations are possible
    
    CONST_FILESTOCHECK = {'*-ztdata.mat', '*-analysisdata.mat', '*.log'};
    
    %{
    CONST_GUI_CIRCLE_SMOOTHNESS = 30; %how smooth the drawn circles will be. these values will be scaled by the radius, displaced by the center coordinates, and connected with a plot to draw a circle. trying to be elegant and drawing it with a plot command and 'o' as the style doesn''t seem to work because of how Matlab scales markers and can give a misleading view of the radius of the region
    CONST_GUI_CIRCLE_POINTSX=cos((0:CONST_GUI_CIRCLE_SMOOTHNESS)*2*pi/CONST_GUI_CIRCLE_SMOOTHNESS); 
    CONST_GUI_CIRCLE_POINTSY=sin((0:CONST_GUI_CIRCLE_SMOOTHNESS)*2*pi/CONST_GUI_CIRCLE_SMOOTHNESS);
    %}
    
    CONST_BEHAVIOUR_NEURON_UNKNOWN = 1;
    CONST_BEHAVIOUR_NEURON_STATIONARY = 2;
    CONST_BEHAVIOUR_NEURON_FORWARDS = 3;
    CONST_BEHAVIOUR_NEURON_REVERSAL = 4;
    CONST_BEHAVIOUR_NEURON_INVALID = 5;
    CONST_BEHAVIOUR_NEURON_BADFRAME = 6;
    CONST_BEHAVIOUR_NEURON_SHORTINTERVAL = 7;
    
    CONST_BEHAVIOUR_TRACKER_UNKNOWN = 0;
    CONST_BEHAVIOUR_TRACKER_FORWARDS = 1;
    CONST_BEHAVIOUR_TRACKER_REVERSAL = 2;
    CONST_BEHAVIOUR_TRACKER_OMEGA = 3;
    CONST_BEHAVIOUR_TRACKER_INVALID = 4;
    
    CONST_TOLOAD_NEURONDATA = {'ratios', 'rationames', 'behaviour', 'framex', 'framey', 'frametime', 'rightregionx', 'rightregiony', 'regionname', 'oxygen'};
    CONST_TOLOAD_TRACKERDATA = {'objects', 'scalingfactor', 'lastframe', 'framerate', 'flashindices'};
	
    %these coefficients were extracted from the beads movies
    CONST_CONVERT_REGIONX_TO_ACTUALX = -0.6277; %-0.6289;
    CONST_CONVERT_REGIONY_TO_ACTUALX = -0.0110; %-0.0077;
    CONST_CONVERT_REGIONX_TO_ACTUALY = -0.0271; %-0.0148;
    CONST_CONVERT_REGIONY_TO_ACTUALY = +0.6427; %+0.6389;
    
    CONST_OXYGEN_UNKNOWN = 1;
    CONST_OXYGEN_DECREASING = 2;
    CONST_OXYGEN_LOW = 3;
    CONST_OXYGEN_HIGH = 4;
    CONST_OXYGEN_INCREASING = 5;
    
    CONST_TRACKER_REGIONNAME = 'behavioural data';
    
    CONST_GUI_SORT_ALPHABETICALLY = 1;
    CONST_GUI_SORT_BYDATE_ASCENDING = 2;
    CONST_GUI_SORT_BYDATE_DESCENDING = 3;
    
    CONST_GUI_BEHAVIOUR_ANYTHING = 1;
    CONST_GUI_BEHAVIOUR_UNKNOWN = 2;
    CONST_GUI_BEHAVIOUR_FORWARDS = 3;
    CONST_GUI_BEHAVIOUR_REVERSAL = 4;
    CONST_GUI_BEHAVIOUR_STATIONARY = 5;
    
    CONST_LOG_LEFTBYRIGHT = 0;
    CONST_LOG_RIGHTBYLEFT = 1;
    
    CONST_GUI_YES = 1; CONST_GUI_ATLEAST = 1;
    CONST_GUI_NO = 2; CONST_GUI_NOT = 2; CONST_GUI_ATMOST = 2;
    CONST_GUI_IRRELEVANT = 3; CONST_GUI_UNKNOWN = 3;
    
    CONST_GUI_COMPARED_BEFORE = 1;
    CONST_GUI_COMPARED_EXACTLY = 2;
    CONST_GUI_COMPARED_AFTER = 3;
    
    CONST_GUI_ALIGN_WHAT_NOTHING = 1;
    CONST_GUI_ALIGN_WHAT_INTERVALS = 2;
    CONST_GUI_ALIGN_WHAT_BEHAVIOUR = 3;
    CONST_GUI_ALIGN_WHAT_SPEED = 4;
    CONST_GUI_ALIGN_WHAT_VELOCITY = 5;
    CONST_GUI_ALIGN_WHAT_OXYGEN = 6;
    CONST_GUI_ALIGN_WHAT_LIGHT = 7;
    CONST_GUI_ALIGN_HOW_START = 1;
    CONST_GUI_ALIGN_HOW_END = 2;
    
    CONST_GUI_TRACE_WHAT_RATIO = 1;
    CONST_GUI_TRACE_WHAT_SPEED = 2;
    CONST_GUI_TRACE_WHAT_VELOCITY = 3;
    CONST_GUI_TRACE_WHAT_DIRECTION = 4;
    CONST_GUI_TRACE_WHAT_REVERSALS = 5;
    CONST_GUI_TRACE_WHAT_REVINIT = 6; %reversal initiation
    CONST_GUI_TRACE_WHAT_REVDUR = 7; %reversal duration
    CONST_GUI_TRACE_WHAT_OMEGAS = 8;
    CONST_GUI_TRACE_WHAT_SPECTRALDENSITY = 9;
    CONST_GUI_TRACE_WHAT_NSPEED = 10;
    CONST_GUI_TRACE_WHAT_NREV = 11;
    CONST_GUI_TRACE_WHAT_NRATIO = 12;
    CONST_GUI_TRACE_HOW_MEAN = 1;
    CONST_GUI_TRACE_HOW_INDIVIDUAL = 2;
    CONST_GUI_ERROR_WHAT_SEM = 1;
    CONST_GUI_ERROR_WHAT_STD = 2;
    CONST_GUI_ERROR_WHAT_NOTHING = 3;
    CONST_GUI_ERROR_HOW_AREA = 1;
    CONST_GUI_ERROR_HOW_LINES = 2;
    CONST_GUI_ERROR_HOW_BARS = 3;
    
    CONST_GUI_LEGEND_NO = 1;
    CONST_GUI_LEGEND_AUTO = 2;
    CONST_GUI_LEGEND_NORTHEAST = 3;
    CONST_GUI_LEGEND_NORTHWEST = 4;
    CONST_GUI_LEGEND_SOUTHEAST = 5;
    CONST_GUI_LEGEND_SOUTHWEST = 6;
    
    CONST_GUI_SCALE_AUTO = 1;
    CONST_GUI_SCALE_MANUAL = 2;
    
    CONST_GUI_COLORDEFAULTS = {'b', 'g', 'r', 'c', 'm', 'y', 'k'};
    
    files = {};
    selectedfiles = {};
    regions = {};
    selectedregions = {};
    selectedoxygens = 1:5;
    oxygenfrom = 1;
    oxygenuntil = Inf;
    
    objects = struct([]);
    objectsn = 0;
    
    beforeframes = 0;
    beforeyes = CONST_GUI_NO;
    beforebehaviour = CONST_GUI_BEHAVIOUR_ANYTHING;
    beforeoutside = true;
    beforeincluded = false;
    
    duringyes = CONST_GUI_YES;
    duringbehaviour = CONST_GUI_BEHAVIOUR_ANYTHING;
    duringframes = 0;
    duringframeshow = CONST_GUI_IRRELEVANT;
    
    afterframes = 0;
    afteryes = CONST_GUI_NO;
    afterbehaviour = CONST_GUI_BEHAVIOUR_ANYTHING;
    afteroutside = true;
    afterincluded = false;
    
    alignwhat = CONST_GUI_ALIGN_WHAT_NOTHING;
    alignhow = CONST_GUI_ALIGN_HOW_START;
    aligntoframe = 0;
    
    binning = 0;
    fromframe = 1;
    untilframe = Inf;
    speedmin = -Inf;
    speedmax = Inf;
    speedover = 0;
    speedbins = '-';
    movingaveragespeed = 1;
    movingaveragevalue = 1;
    
    r0from = 0;
    r0until = NaN;
    
    i1from = NaN;
    i1until = NaN;
    i2from = NaN;
    i2until = NaN;
    sminframes = 10;
    uminframes = 20;
    u1 = [];
    u2 = [];
    %t1 = [];
    %t2 = [];
    %z1mean = [];
    %z2mean = [];
    %z1var = [];
    %z2var = [];
    %z1n = [];
    %z2n = [];
    
    successivemovies = true;
    sortby = CONST_GUI_SORT_BYDATE_DESCENDING;
    displaytracewhat = CONST_GUI_TRACE_WHAT_RATIO;
    displaytracehow = CONST_GUI_TRACE_HOW_MEAN;
    displayerrorwhat = CONST_GUI_ERROR_WHAT_SEM;
    displayerrorhow = CONST_GUI_ERROR_HOW_AREA;
    
    legendwhere = CONST_GUI_LEGEND_NORTHEAST;
    showgrid = false;
    normalize = false;
    deltaroverr = false;
    transparent = true;
    
    legendtraces = {};
    legendnames = {};
    
    colortrace = CONST_GUI_COLORDEFAULTS{1};
    colorerror = CONST_GUI_COLORDEFAULTS{1};
    
    valuesmin = -Inf;
    valuesmax = Inf;
    displayxstyle = CONST_GUI_SCALE_AUTO;
    xmin = 0;
    xmax = 1;
    displayystyle = CONST_GUI_SCALE_AUTO;
    ymin = 0;
    ymax = 1;
    
    gui.fig = figure('Name',['Metaverage ' version],'NumberTitle','off', ...
        'Visible','on','Color',get(0,'defaultUicontrolBackgroundColor'), 'Units','Normalized',...
        'DefaultUicontrolUnits','Normalized', 'DeleteFcn', @savesettings);
    
    gui.datapanel = uipanel(gui.fig,'Title','File selection','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.00 0.00 0.20 1.00]);
    gui.sortby = uicontrol(gui.datapanel, 'Style','Popupmenu','String',{'Alphabetical', 'Ascending by date', 'Descending by date'},'Value',sortby,'Position',[0.00 0.95 0.50 0.05],'Callback',{@setvalue,'number','setglobal','sortby','finally','updatefilelist'});
    
    gui.refresh = uicontrol(gui.datapanel, 'Style','Pushbutton','String','Refresh','Position',[0.50 0.95 0.25 0.05],'Callback',@updatefilelist);
    gui.browse = uicontrol(gui.datapanel,'Style','Pushbutton','String','Browse','Position',[0.75 0.95 0.25 0.05],'Callback',@browse);
    
    gui.foldertext = uicontrol(gui.datapanel,'Style','Text','String','Folder:','Position',[0.00 0.90 0.15 0.035]);
    gui.folder = uicontrol(gui.datapanel,'Style','Edit','String','','HorizontalAlignment','left','BackgroundColor','w','Position',[0.15 0.90 0.85 0.05],'Callback',@updatefilelist);
    
    gui.filefiltertext = uicontrol(gui.datapanel,'Style','Text','String','Filter:','Position',[0.00 0.85 0.15 0.035]);
    gui.filefilter = uicontrol(gui.datapanel,'Style','Edit','String','','HorizontalAlignment','left','BackgroundColor','w','Position',[0.15 0.85 0.85 0.05],'Callback',@updatefilelist);
    
    gui.files = uicontrol(gui.datapanel,'Style','Listbox','String',files,'BackgroundColor','w','Position',[0.00 0.10 1.00 0.75],'Min',0,'Max',intmax('uint32'),'Value',[],'Callback',@selectfile);
    
    gui.readdata = uicontrol(gui.datapanel,'Style','Pushbutton','String','Read data','Position',[0.00 0.03 0.60 0.07],'Callback',@readdata);
    gui.unloaddata = uicontrol(gui.datapanel,'Style','Pushbutton','String','Unload data','Position',[0.60 0.03 0.40 0.07],'Callback',@unloaddata,'Enable','off');
    
    %gui.readvariance = uicontrol(gui.datapanel,'Style','Checkbox','String','Calculate variance','Position',[0.00 0.00 0.50 0.03],'Value',readvariance,'Callback',{@setvalue,'logical','setglobal','readvariance'});
    %gui.loadanalysis = uicontrol(gui.datapanel, 'Style','Pushbutton','String','Load settings','Position',[0.00 0.00 0.50 0.05],'Callback',@loadanalysis);
    %gui.saveanalysis = uicontrol(gui.datapanel, 'Style','Pushbutton','String','Save settings','Position',[0.50 0.00 0.50 0.05],'Callback',@saveanalysis);
    
    
    gui.successivemovies = uicontrol(gui.datapanel,'Style','Checkbox','String','Successive movies','Value',successivemovies,'Position',[0.50 0.000 0.50 0.03],'Callback',{@setvalue, 'logical', 'setglobal', 'successivemovies'});
    
    gui.displaypanel = uipanel(gui.fig,'Title','Display','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.20 0.10 0.60 0.90]);
    gui.mainimage = axes('Parent',gui.displaypanel,'Visible','on','Position',[0.10 0.10 0.80 0.80]);
    
    gui.displaysettingspanel = uipanel(gui.fig,'Title','Display settings','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.20 0.00 0.24 0.10]);
    
    gui.displayvaluestext = uicontrol(gui.displaysettingspanel,'Style','Text','String','Values between','Position',[0.00 0.50 0.25 0.30]);
    gui.displayvaluesmin = uicontrol(gui.displaysettingspanel,'Style','Edit','String',valuesmin,'Position',[0.00 0.00 0.12 0.50],'Callback',{@setvalue, 'default', NaN, 'setglobal', 'valuesmin', 'finally', 'checkoptions'});
    gui.displayvaluesmax = uicontrol(gui.displaysettingspanel,'Style','Edit','String',valuesmax,'Position',[0.13 0.00 0.12 0.50],'Callback',{@setvalue, 'default', NaN, 'setglobal', 'valuesmax', 'finally', 'checkoptions'});
    
    gui.displayxstyle = uicontrol(gui.displaysettingspanel,'Style','Popupmenu','String',{'Autoscale X', 'Manual X'},'Value', displayxstyle, 'Position',[0.25 0.50 0.25 0.50],'Callback',{@setvalue, 'number', 'setglobal', 'displayxstyle', 'finally', {'checkoptions', 'checkfigure'}});
    gui.displayxmin = uicontrol(gui.displaysettingspanel,'Style','Edit','String',xmin,'Position',[0.25 0.00 0.12 0.50],'Callback',{@setvalue, 'default', 0, 'setglobal', 'xmin', 'finally', 'checkfigure'});
    gui.displayxmax = uicontrol(gui.displaysettingspanel,'Style','Edit','String',xmax,'Position',[0.38 0.00 0.12 0.50],'Callback',{@setvalue, 'default', 1, 'setglobal', 'xmax', 'finally', 'checkfigure'});
    gui.displayystyle = uicontrol(gui.displaysettingspanel,'Style','Popupmenu','String',{'Autoscale Y', 'Manual Y'},'Value', displayystyle, 'Position',[0.50 0.50 0.25 0.50],'Callback',{@setvalue, 'number', 'setglobal', 'displayystyle', 'finally', {'checkoptions', 'checkfigure'}});
    gui.displayymin = uicontrol(gui.displaysettingspanel,'Style','Edit','String',ymin,'Position',[0.50 0.00 0.12 0.50],'Callback',{@setvalue, 'default', 0, 'setglobal', 'ymin', 'finally', 'checkfigure'});
    gui.displayymax = uicontrol(gui.displaysettingspanel,'Style','Edit','String',ymax,'Position',[0.63 0.00 0.12 0.50],'Callback',{@setvalue, 'default', 1, 'setglobal', 'ymax', 'finally', 'checkfigure'});
    
    gui.showgrid = uicontrol(gui.displaysettingspanel,'Style','Checkbox','String','Show grid','Value',showgrid,'Position',[0.75 0.70 0.25 0.30],'Callback',{@setvalue, 'logical', 'setglobal', 'showgrid', 'finally', 'checkfigure'});
    gui.legendwhere = uicontrol(gui.displaysettingspanel,'Style','Popupmenu','String',{'No legend', 'Auto legend', 'NE legend', 'NW legend', 'SE legend', 'SW legend'},'Value',legendwhere,'Position',[0.75 0.35 0.25 0.30],'Callback',{@setvalue, 'number', 'setglobal', 'legendwhere', 'finally', 'checkfigure'});
    
    gui.displaycommandspanel = uipanel(gui.fig,'Title','Display commands','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.44 0.00 0.36 0.10]);
    
    gui.displayclear = uicontrol(gui.displaycommandspanel,'Style','Pushbutton','String','Clear plot','Position',[0.00 0.00 0.16 1.00],'Callback',@clearplot);
    
    gui.displaytracehow = uicontrol(gui.displaycommandspanel,'Style','Popupmenu','String',{'Mean','Individual'},'Value',displaytracehow,'Position',[0.17 0.50 0.16 0.50],'Callback',{@setvalue, 'number', 'setglobal', 'displaytracehow', 'finally', 'checkoptions'});
    gui.displaytracewhat = uicontrol(gui.displaycommandspanel,'Style','Popupmenu','String',{'ratios','speed','velocity','direction','rev prop','rev init','rev dur', 'omegas', 'spectral density', 'n (speed)', 'n (reversals)', 'n (ratios)'},'Value',displaytracewhat,'Position',[0.33 0.50 0.16 0.50],'Callback',{@setvalue, 'number', 'setglobal', 'displaytracewhat', 'finally', 'checkoptions'});
    
    gui.displayerrorwhat = uicontrol(gui.displaycommandspanel,'Style','Popupmenu','String',{'+/- SEM','+/- STD','Neither'},'Value',displayerrorwhat,'Position',[0.17 0.00 0.16 0.50],'Callback',{@setvalue, 'number', 'setglobal', 'displayerrorwhat', 'finally', 'checkoptions'});
    gui.displayerrorhow = uicontrol(gui.displaycommandspanel,'Style','Popupmenu','String',{'as area','as lines','as bars'},'Value',displayerrorhow,'Position',[0.33 0.00 0.16 0.50],'Callback',{@setvalue, 'number', 'setglobal', 'displayerrorhow', 'finally', 'checkoptions'});
    
    gui.displaycolortracetext = uicontrol(gui.displaycommandspanel,'Style','Text','String','Trace colour','Position',[0.50 0.50 0.075 0.50]);
    gui.displaycolortrace = uicontrol(gui.displaycommandspanel,'Style','Edit','String',colortrace,'Position',[0.50 0.00 0.075 0.50],'Callback',{@setvalue, 'string', 'setglobal', 'colortrace', 'finally', 'checkoptions'});
    gui.displaycolorerrortext = uicontrol(gui.displaycommandspanel,'Style','Text','String','Error colour','Position',[0.575 0.50 0.075 0.50]);
    gui.displaycolorerror = uicontrol(gui.displaycommandspanel,'Style','Edit','String',colorerror,'Position',[0.575 0.00 0.075 0.50],'Callback',{@setvalue, 'string', 'setglobal', 'colorerror', 'finally', 'checkoptions'});
    
    gui.normalize = uicontrol(gui.displaycommandspanel,'Style','Checkbox','String','normalize','Value',normalize,'Position',[0.68 0.70 0.14 0.30],'Callback',{@setvalue, 'logical', 'setglobal', 'normalize'});
    gui.deltaroverr = uicontrol(gui.displaycommandspanel,'Style','Checkbox','String','deltaR/R0','Value',deltaroverr,'Position',[0.68 0.35 0.14 0.30],'Callback',{@setvalue, 'logical', 'setglobal', 'deltaroverr'});
    gui.transparent = uicontrol(gui.displaycommandspanel,'Style','Checkbox','String','transparent','Value',transparent,'Position',[0.68 0.05 0.14 0.30],'Callback',{@setvalue, 'logical', 'setglobal', 'transparent'});
    
    gui.popupfigure = uicontrol(gui.displaycommandspanel,'Style','Pushbutton','String','Popup figure','Position',[0.84 0.00 0.16 0.30],'Callback',@popupfigure);
    
    gui.plotit = uicontrol(gui.displaycommandspanel,'Style','Pushbutton','String','Add to plot','Position',[0.84 0.30 0.16 0.70],'Callback',@plotit);
    
    gui.behaviourpanel = uipanel(gui.fig,'Title','Behaviour settings','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.80 0.10 0.20 0.90]);
    
    gui.beforetext = uicontrol(gui.behaviourpanel,'Style','Text','String','before:','Position',[0.00 0.95 0.30 0.03]);
    gui.beforeframeshowtext = uicontrol(gui.behaviourpanel,'Style','Text','String','at least','Position',[0.00 0.90 0.30 0.04]);
    gui.beforeframes = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(beforeframes),'Position',[0.00 0.85 0.12 0.05],'Callback',{@setvalue, 'default', 0, 'min', 0, 'round', 1, 'setglobal', 'beforeframes'});
    gui.beforeframestext = uicontrol(gui.behaviourpanel,'Style','Text','String','frames of','Position',[0.12 0.85 0.18 0.03]);
    gui.beforeyes = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{' ','not'},'Value',beforeyes,'Position',[0.00 0.80 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'beforeyes'});
    gui.beforebehaviour = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{'anything','unknown','forwards','reversal','stationary'},'Value',beforebehaviour,'Position',[0.00 0.76 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'beforebehaviour'});
    gui.beforeoutside = uicontrol(gui.behaviourpanel,'Style','Checkbox','String','can start outside','Value',beforeoutside,'Position',[0.00 0.70 0.30 0.05],'Callback', {@setvalue, 'logical', 'setglobal', 'beforeoutside'});
    gui.beforeincluded = uicontrol(gui.behaviourpanel,'Style','Checkbox','String','included','Value',beforeincluded,'Position',[0.00 0.65 0.30 0.05],'Callback', {@setvalue, 'logical', 'setglobal', 'beforeincluded'});
    
    gui.duringbehaviourtext = uicontrol(gui.behaviourpanel,'Style','Text','String','during:','Position',[0.35 0.95 0.30 0.03]);
    gui.duringframeshow = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{'at least','at most','any number of'},'Value',duringframeshow,'Position',[0.35 0.90 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'duringframeshow', 'finally', 'checkoptions'});
    gui.duringframes = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(duringframes),'Position',[0.35 0.85 0.12 0.05],'Callback',{@setvalue, 'default', 0, 'min', 0, 'round', 1, 'setglobal', 'duringframes'});
    gui.duringframestext = uicontrol(gui.behaviourpanel,'Style','Text','String','frames of','Position',[0.47 0.85 0.18 0.03]);
    gui.duringyes = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{' ','not'},'Value',duringyes,'Position',[0.35 0.80 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'duringyes'});
    gui.duringbehaviour = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{'anything','unknown','forwards','reversal','stationary'},'Value',duringbehaviour,'Position',[0.35 0.76 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'duringbehaviour'});
    
    gui.aligntext = uicontrol(gui.behaviourpanel,'Style','Text','String','aligned by','Position',[0.35 0.74 0.30 0.02]);
    gui.alignwhat = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{'nothing','intervals','behaviour','speed','velocity','oxygen','light'},'Value',alignwhat,'Position',[0.35 0.70 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'alignwhat', 'finally', 'checkoptions'});
    gui.alignhow = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{'beginnings','endings'},'Value',alignhow,'Position',[0.35 0.66 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'alignhow'});
    gui.aligntoframetext = uicontrol(gui.behaviourpanel,'Style','Text','String','at frame','Position',[0.35 0.64 0.30 0.02]);
    gui.aligntoframe = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(aligntoframe),'Position',[0.35 0.59 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'round', 1, 'setglobal', 'aligntoframe'});
    
    gui.aftertext = uicontrol(gui.behaviourpanel,'Style','Text','String','after:','Position',[0.70 0.95 0.30 0.03]);
    gui.afterframeshowtext = uicontrol(gui.behaviourpanel,'Style','Text','String','at least','Position',[0.70 0.90 0.30 0.04]);
    gui.afterframes = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(afterframes),'Position',[0.70 0.85 0.12 0.05],'Callback',{@setvalue, 'default', 0, 'min', 0, 'round', 1, 'setglobal', 'afterframes'});
    gui.afterframestext = uicontrol(gui.behaviourpanel,'Style','Text','String','frames of','Position',[0.82 0.85 0.18 0.03]);
    gui.afteryes = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{' ','not'},'Value',afteryes,'Position',[0.70 0.80 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'afteryes'});
    gui.afterbehaviour = uicontrol(gui.behaviourpanel,'Style','Popupmenu','String',{'anything','unknown','forwards','reversal','stationary'},'Value',afterbehaviour,'Position',[0.70 0.76 0.30 0.04],'Callback',{@setvalue, 'number', 'setglobal', 'afterbehaviour'});
    gui.afteroutside = uicontrol(gui.behaviourpanel,'Style','Checkbox','String','can end outside','Value',afteroutside,'Position',[0.70 0.70 0.30 0.05],'Callback', {@setvalue, 'logical', 'setglobal', 'afteroutside'});
    gui.afterincluded = uicontrol(gui.behaviourpanel,'Style','Checkbox','String','included','Value',afterincluded,'Position',[0.70 0.65 0.30 0.05],'Callback', {@setvalue, 'logical', 'setglobal', 'afterincluded'});
    
    gui.r0text = uicontrol(gui.behaviourpanel,'Style','Text','String','R0 from-until','Position',[0.00 0.63 0.30 0.02]);
    gui.r0from = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(r0from),'Position',[0.00 0.60 0.14 0.03],'Callback',{@setvalue, 'default', NaN, 'round', 1, 'min', 0, 'setglobal', 'r0from'});
    gui.r0until = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(r0until),'Position',[0.16 0.60 0.14 0.03],'Callback',{@setvalue, 'default', NaN, 'round', 1, 'setglobal', 'r0until'});
    
    gui.i1text = uicontrol(gui.behaviourpanel,'Style','Text','String','i1 from-until','Position',[0.00 0.57 0.30 0.02]);
    gui.i1from = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(i1from),'Position',[0.00 0.52 0.14 0.05],'Callback',{@setvalue, 'default', NaN, 'round', 1, 'min', 0, 'setglobal', 'i1from'});
    gui.i1until = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(i1until),'Position',[0.16 0.52 0.14 0.05],'Callback',{@setvalue, 'default', NaN, 'round', 1, 'min', 0, 'setglobal', 'i1until'});
    gui.i2text = uicontrol(gui.behaviourpanel,'Style','Text','String','i2 from-until','Position',[0.35 0.57 0.30 0.02]);
    gui.i2from = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(i2from),'Position',[0.35 0.52 0.14 0.05],'Callback',{@setvalue, 'default', NaN, 'round', 1, 'min', 0, 'setglobal', 'i2from'});
    gui.i2until = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(i2until),'Position',[0.51 0.52 0.14 0.05],'Callback',{@setvalue, 'default', NaN, 'round', 1, 'min', 0, 'setglobal', 'i2until'});
    %gui.z1add = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','z1','Position',[0.70 0.56 0.09 0.03],'Callback',@z1add);
    %gui.z2add = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','z2','Position',[0.80 0.56 0.09 0.03],'Callback',@z2add);
    gui.sminframestext = uicontrol(gui.behaviourpanel,'Style','Text','String','min:','Position',[0.90 0.555 0.09 0.02]);
    gui.sminframes = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(sminframes),'Position',[0.90 0.52 0.10 0.03],'Callback',{@setvalue, 'default', 1, 'min', 1, 'round', 1, 'setglobal', 'sminframes'});
    gui.ssign = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','Sign test', 'Position',[0.70 0.55 0.19 0.03],'Callback',@ssign);
    gui.pairedt = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','Paired t', 'Position',[0.70 0.52 0.19 0.03],'Callback',@pairedt);
    gui.u1add = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','u1','Position',[0.70 0.62 0.09 0.03],'Callback',@u1add);
    gui.u2add = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','u2','Position',[0.80 0.62 0.09 0.03],'Callback',@u2add);
    gui.uminframestext = uicontrol(gui.behaviourpanel,'Style','Text','String','min:','Position',[0.90 0.625 0.09 0.02]);
    gui.uminframes = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(uminframes),'Position',[0.90 0.59 0.10 0.03],'Callback',{@setvalue, 'default', 1, 'min', 1, 'round', 1, 'setglobal', 'uminframes'});
    gui.ks = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','KS', 'Position',[0.70 0.59 0.066 0.03],'Callback',@ks);
    gui.rsum = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','U', 'Position',[0.766 0.59 0.066 0.03],'Callback',@rsum);
    gui.unpairedt = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','t', 'Position',[0.833 0.59 0.066 0.03],'Callback',@unpairedt);
    %gui.t1add = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','t1','Position',[0.70 0.52 0.09 0.03],'Callback',@t1add);
    %gui.t2add = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','t2','Position',[0.80 0.52 0.09 0.03],'Callback',@t2add);
    %gui.tzen = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','zen', 'Position',[0.70 0.60 0.19 0.03],'Callback',@tzen);
    %gui.tpaired = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','paired','Position',[0.90 0.555 0.09 0.03],'Callback',@tpaired);
    %gui.tunpaired = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton','String','unpaired','Position',[0.90 0.52 0.09 0.03],'Callback',@tunpaired);
    
    gui.binningtext = uicontrol(gui.behaviourpanel,'Style','Text','String','binning (s)','Position',[0.70 0.50 0.30 0.02]);
    gui.binning = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(binning),'Position',[0.70 0.45 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'setglobal', 'binning'});
    gui.fromframetext = uicontrol(gui.behaviourpanel,'Style','Text','String','from frame','Position',[0.00 0.50 0.30 0.02]);
    gui.fromframe = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(fromframe),'Position',[0.00 0.45 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'setglobal', 'fromframe'});
    gui.untilframetext = uicontrol(gui.behaviourpanel,'Style','Text','String','until frame','Position',[0.35 0.50 0.30 0.02]);
    gui.untilframe = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(untilframe),'Position',[0.35 0.45 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'setglobal', 'untilframe'});
    gui.speedmintext = uicontrol(gui.behaviourpanel,'Style','Text','String','speed min (um/s)','Position',[0.00 0.40 0.30 0.02]);
    gui.speedmin = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(speedmin),'Position',[0.00 0.35 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'setglobal', 'speedmin'});
    gui.speedmaxtext = uicontrol(gui.behaviourpanel,'Style','Text','String','speed max (um/s)','Position',[0.35 0.40 0.30 0.02]);
    gui.speedmax = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(speedmax),'Position',[0.35 0.35 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'setglobal', 'speedmax'});
    gui.speedbinstext = uicontrol(gui.behaviourpanel,'Style','Text','String','speed bins (um/s)','Position',[0.35 0.30 0.30 0.02]);
    gui.speedbins = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(speedbins),'Position',[0.35 0.25 0.30 0.05],'Callback',{@setvalue, 'string', 'default', '-', 'setglobal', 'speedbins'});
    gui.speedovertext = uicontrol(gui.behaviourpanel,'Style','Text','String','speed over (s)','Position',[0.00 0.30 0.30 0.02]);
    gui.speedover = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(speedover),'Position',[0.00 0.25 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'finally', 'checkspeedover'});
    gui.movingaveragespeedtext = uicontrol(gui.behaviourpanel,'Style','Text','String','moving average (speed, frames)','Position',[0.00 0.20 0.30 0.04]);
    gui.movingaveragespeed = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(movingaveragespeed),'Position',[0.00 0.15 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'setglobal', 'movingaveragespeed'});
    gui.movingaveragevaluetext = uicontrol(gui.behaviourpanel,'Style','Text','String','moving average (values, frames)','Position',[0.35 0.20 0.30 0.04]);
    gui.movingaveragevalue = uicontrol(gui.behaviourpanel,'Style','Edit','String',num2str(movingaveragevalue),'Position',[0.35 0.15 0.30 0.05],'Callback',{@setvalue, 'default', 0, 'setglobal', 'movingaveragevalue'});
    
    gui.oxygentext = uicontrol(gui.behaviourpanel,'Style','Text','String','oxygen','Position',[0.00 0.12 0.30 0.02]);
    gui.oxygen = uicontrol(gui.behaviourpanel,'Style','Listbox','String',{'Unknown', 'Decreasing', 'Low steady', 'High steady', 'Increasing'},'BackgroundColor','w','Position',[0.00 0.00 0.30 0.12],'Value', selectedoxygens, 'Min', 0, 'Max', intmax('uint32'), 'Callback', @selectoxygen);
    gui.oxygenframestext = uicontrol(gui.behaviourpanel,'Style','Text','String','between frames','Position',[0.35 0.12 0.30 0.02]);
    gui.oxygenfrom = uicontrol(gui.behaviourpanel,'Style','Edit','String',oxygenfrom,'Position',[0.35 0.07 0.12 0.05],'Callback',{@setvalue, 'default', 1, 'min', 1, 'round', 1, 'setglobal', 'oxygenfrom'});
    gui.oxygenuntil = uicontrol(gui.behaviourpanel,'Style','Edit','String',oxygenuntil,'Position',[0.48 0.07 0.12 0.05],'Callback',{@setvalue, 'default', Inf, 'min', 1, 'round', 1, 'setglobal', 'oxygenuntil'});
    gui.oxygenset = uicontrol(gui.behaviourpanel, 'Style', 'Pushbutton', 'String', 'Set O2', 'Position',[0.35 0.00 0.30 0.05],'Callback',@setoxygen);
    
    gui.regiontext = uicontrol(gui.behaviourpanel,'Style','Text','String','regions','Position',[0.70 0.40 0.30 0.02]);
    gui.regions = uicontrol(gui.behaviourpanel,'Style','Listbox','String',regions,'BackgroundColor','w','Position',[0.70 0.05 0.30 0.35],'Min', 0, 'Max', intmax('uint32'), 'Callback',@selectregion);
    gui.regiondisplay = uicontrol(gui.behaviourpanel,'Style','Pushbutton','String','Display files','Position',[0.70 0.00 0.30 0.05],'Callback',@displayfiles);
    
    %gui.middleset = uicontrol(gui.behaviourpanel,'Style','Pushbutton','String','Set everywhere','Position',[0.35 0.72 0.30 0.05],'Callback',@setmiddleeverywhere);
    
    gui.exportpanel = uipanel(gui.fig,'Title','Export','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.80 0.00 0.05 0.10]);
    gui.export = uicontrol(gui.exportpanel, 'Style', 'Checkbox', 'String', 'Export',...
        'Position',[0.00 0.00 1.00 1.00]);%, 'Callback', @export);
    
    gui.debuggingpanel = uipanel(gui.fig,'Title','Debug','Units','Normalized',...
        'DefaultUicontrolUnits','Normalized','Position',[0.85 0.00 0.15 0.10]);
    gui.debuggingfunction = uicontrol(gui.debuggingpanel, 'Style', 'Pushbutton', 'String', 'Debugging function',...
        'Position',[0.00 0.00 1.00 1.00], 'Callback', @debuggingfunction);
    
    clearobjects;
    loadsettings;
    updatefilelist;
    checkoptions;
    checkcanread;
    
    function updatefilelist(hobj,eventdata) %#ok<INUSD>
        folder = get(gui.folder, 'String');
        filefilter = get(gui.filefilter, 'String');
        files = {};
        
        %CHANGEME START
        %{
        currentloaded = load('AVBAIYfilenames');
        %files = currentloaded.filenames(~isnan(currentloaded.avbwhere));
        files = currentloaded.filenames;
        currentloaded = load('AVAfilenames');
        files(end+1:end+numel(currentloaded.filenames)) = currentloaded.filenames;
        currentloaded = load('AIAfilenames');
        files(end+1:end+numel(currentloaded.filenames)) = currentloaded.filenames;
        currentloaded = load('AIBfilenames');
        files(end+1:end+numel(currentloaded.filenames)) = currentloaded.filenames;
        currentloaded = load('RMGfilenames');
        files(end+1:end+numel(currentloaded.filenames)) = currentloaded.filenames;
        %}
        
        for i=1:numel(CONST_FILESTOCHECK);
            currentfiles = dir(fullfile(folder, ['*' filefilter CONST_FILESTOCHECK{i}]));
            if sortby == CONST_GUI_SORT_BYDATE_ASCENDING || sortby == CONST_GUI_SORT_BYDATE_DESCENDING
                if sortby == CONST_GUI_SORT_BYDATE_ASCENDING
                    sortdirection = 'ascend';
                elseif sortby == CONST_GUI_SORT_BYDATE_DESCENDING
                    sortdirection = 'descend';
                end
                dates = vertcat(currentfiles.datenum);
                [datessorted, datessortedindex] = sort(dates, sortdirection);
                currentfiles = currentfiles(datessortedindex);
            end
            files(end+1:end+numel(currentfiles)) = {currentfiles.name};
        end
        %CHANGEME END
        
        if isempty(files)
            set(gui.files,'String','');
        else
            set(gui.files,'String',files);
            set(gui.files,'Value',[]);
            set(gui.files,'ListBoxTop',1);
        end
        selectfile;
    end
    
    function selectfile(hobj, eventdata) %#ok<INUSD>
        allstrings = get(gui.files,'String');
        if ~isempty(allstrings)
            selectedfiles = allstrings(get(gui.files,'Value'));
            selectedfiles = sort(selectedfiles); %we need to sort it alphabetically (internally) because we want to read split movies in the right order to be able to merge the following movies on top of the initial one (which therefore needs to be read first)
        else
            selectedfiles = [];
        end
    end

    function selectregion(hobj, eventdata) %#ok<INUSD>
        allstrings = get(gui.regions,'String');
        if ~isempty(allstrings)
            selectedregions = allstrings(get(gui.regions,'Value'));
        else
            selectedregions = [];
        end
    end

    function selectoxygen (hobj, eventdata) %#ok<INUSD>
        selectedoxygens = get(gui.oxygen,'Value');
    end
    
    % Select a new data folder graphically
    function browse(hobj,eventdata) %#ok<INUSD>
        newdirectory = uigetdir(get(gui.folder, 'String'), 'Select data folder');
        if newdirectory ~= 0
            set(gui.folder, 'String', newdirectory);
            updatefilelist;
        end
    end

    function setoxygen(hobj, eventdata)%#ok<INUSD>
        
        setoxygentowhat = get(gui.oxygen, 'Value');
        
        if numel(setoxygentowhat) ~= 1
            questdlg('You must select a single oxygen concentration to set the values to.', 'Setting oxygen', 'OK', 'OK');
            return;
        end
        
        if strcmp(questdlg('Warning: setting the oxygen values involves writing into (appending to) multiple analysis savefiles. Are you sure you want to proceed?','Setting oxygen','Proceed','Cancel','Proceed'),'Cancel')
            return;
        end
        
        couldnotset = false;
        
        for i=1:numel(selectedfiles)
            warning('off', 'MATLAB:load:variableNotFound');
            currentlyloaded = load(fullfile(get(gui.folder, 'String'), selectedfiles{i}), 'oxygen', 'ratios');
            warning('on', 'MATLAB:load:variableNotFound');
            if isfield(currentlyloaded, 'ratios')
                nf = size(currentlyloaded.ratios, 1);
            else %not a neuron file but instead a zentracker one probably
                fprintf(2, 'Warning: the savefile %s does not contain a ratios variable. Skipping it without setting the oxygen variable...\n', selectedfiles{i});
                couldnotset = true;
                continue;
            end
            if isfield(currentlyloaded, 'oxygen')
                oxygen = currentlyloaded.oxygen;
            else
                oxygen = ones(1, nf)*CONST_OXYGEN_UNKNOWN;
            end
            currentoxygenfrom = max([oxygenfrom 1]);
            currentoxygenuntil = min([oxygenuntil nf]);
            oxygen(currentoxygenfrom:currentoxygenuntil) = setoxygentowhat; %#ok<NASGU>
            save(fullfile(get(gui.folder, 'String'), selectedfiles{i}), 'oxygen', '-append');
        end
        
        if couldnotset
            questdlg('Warning: some files were skipped because they did not contain ratios variables (check the command window / standard output).', 'Setting oxygen', 'OK', 'OK');
        end
        
    end
    
    function savesettings (hobj, eventdata) %#ok<INUSD>
        settingsdata = struct;
        settingsdata.figureposition = get(gui.fig, 'OuterPosition');
        settingsdata.folder = get(gui.folder,'String');
        settingsdata.filefilter = get(gui.filefilter,'String');
        if ~isempty(settingsdata.figureposition)
            save([mfilename '-options.mat'], '-struct', 'settingsdata');
        end
    end
    
    function loadsettings(hobj, eventdata) %#ok<INUSD>
        if (exist([mfilename '-options.mat'], 'file') ~= 0) %If position savefile exists
            settingsdata = load([mfilename '-options.mat']);
            if isfield(settingsdata, 'figureposition')
                set(gui.fig, 'OuterPosition', settingsdata.figureposition);
            end
            if isfield(settingsdata, 'folder')
                set(gui.folder,'String', settingsdata.folder);
            end
            if isfield(settingsdata, 'filefilter')
                set(gui.filefilter, 'String', settingsdata.filefilter);
            end
        %else
            %set(gui.fig, 'OuterPosition', get(0, 'Screensize')); %this doesn't seem to work in practice for some weird reason
        end
    end

    %{
    function setmiddleeverywhere (hobj, eventdata) %#ok<INUSD>
        
        %startdisplacement = 0;
        %startcompared = CONST_GUI_COMPARED_EXACTLY;
        beforeyes = middleyes;
        beforebehaviour = middlebehaviour;
        if beforeyes == CONST_GUI_YES, previousyes = CONST_GUI_NO; elseif beforeyes == CONST_GUI_NO, previousyes = CONST_GUI_YES; end
        previousbehaviour = middlebehaviour;
        
        %enddisplacement = 0;
        %endcompared = CONST_GUI_COMPARED_EXACTLY;
        afteryes = middleyes;
        afterbehaviour = middlebehaviour;
        if afteryes == CONST_GUI_YES, nextyes = CONST_GUI_NO; elseif afteryes == CONST_GUI_NO, nextyes = CONST_GUI_YES; end
        nextbehaviour = middlebehaviour;
        
        updatebehaviour;
    end
    %}  

    function displayfiles (hobj, eventdata) %#ok<INUSD>
        filestodisplay = [];
        for i=1:numel(objects)
            for j=1:numel(objects(i).filenames)
                if ismember(objects(i).regionname, selectedregions)
                    if ~isempty(filestodisplay) && ismember(objects(i).filenames{j}, {filestodisplay.filename})
                        whichfiletoadd = find(cellfun(@(x)strcmp(x,objects(i).filenames{j}),{filestodisplay.filename}));
                    else
                        whichfiletoadd = numel(filestodisplay)+1;
                    end
                    filestodisplay(whichfiletoadd).filename = objects(i).filenames{j}; %#ok<AGROW>
                    if isfield(filestodisplay(whichfiletoadd), 'regionname') && ~isempty(filestodisplay(whichfiletoadd).regionname)
                        whichregiontoadd = numel(filestodisplay(whichfiletoadd).regionname) + 1;
                    else
                        whichregiontoadd = 1;
                    end
                    filestodisplay(whichfiletoadd).regionname{whichregiontoadd} = objects(i).regionname; %#ok<AGROW>
                end
            end
        end
        
        %objects were created in the order of filenames, which were already sorted alphabetically internally, so no need to sort filenames here
        %[sortedfilenames sortindices] = sort({filestodisplay.filename});
        %filestodisplay = filestodisplay(sortindices);
        
        for i=1:numel(filestodisplay)
            fprintf('File %s contains the region', filestodisplay(i).filename);
            if numel(filestodisplay(i).regionname) > 1
                fprintf('s');
            end
            fprintf(': ');
            for j=1:numel(filestodisplay(i).regionname)
                if j ~= 1
                    fprintf(', ');
                end
                fprintf('%s', strtrim(filestodisplay(i).regionname{j}));
            end
            fprintf('.\n');
        end
    end
    
    %{
    function updatebehaviour (hobj, eventdata) %#ok<INUSD>
        set(gui.startdisplacement, 'String', num2str(startdisplacement));
        set(gui.startcompared, 'Value', startcompared);
        set(gui.beforeyes, 'Value', beforeyes);
        set(gui.beforebehaviour, 'Value', beforebehaviour);
        set(gui.previousyes, 'Value', previousyes);
        set(gui.previousbehaviour, 'Value', previousbehaviour);
        
        set(gui.enddisplacement, 'String', num2str(enddisplacement));
        set(gui.endcompared, 'Value', endcompared);
        set(gui.afteryes, 'Value', afteryes);
        set(gui.afterbehaviour, 'Value', afterbehaviour);
        set(gui.nextyes, 'Value', nextyes);
        set(gui.nextbehaviour, 'Value', nextbehaviour);
        
        checkoptions;
    end
    %}

    function checkfigure (hobj, eventdata) %#ok<INUSD>
        if displayxstyle == CONST_GUI_SCALE_AUTO
            set(gui.mainimage, 'XLimMode', 'auto');
            xlims = get(gui.mainimage, 'XLim');
            xmin = xlims(1);
            xmax = xlims(2);
            set(gui.displayxmin, 'String', num2str(xmin));
            set(gui.displayxmax, 'String', num2str(xmax));
        else
            set(gui.mainimage, 'XLimMode', 'manual');
            set(gui.mainimage, 'Xlim', [xmin xmax]);
        end
        if displayystyle == CONST_GUI_SCALE_AUTO
            set(gui.mainimage, 'YLimMode', 'auto');
            ylims = get(gui.mainimage, 'YLim');
            ymin = ylims(1);
            ymax = ylims(2);
            set(gui.displayymin, 'String', num2str(ymin));
            set(gui.displayymax, 'String', num2str(ymax));
        else
            set(gui.mainimage, 'YLimMode', 'manual');
            set(gui.mainimage, 'Ylim', [ymin ymax]);
        end
        if showgrid
            set(gui.mainimage, 'XGrid', 'on');
            set(gui.mainimage, 'YGrid', 'on');
        else
            set(gui.mainimage, 'XGrid', 'off');
            set(gui.mainimage, 'YGrid', 'off');
        end
        displaylegend;
    end
    
    function checkoptions (hobj, eventdata) %#ok<INUSD>
        if displaytracehow == CONST_GUI_TRACE_HOW_INDIVIDUAL %Not drawing mean
            set(gui.displayerrorwhat, 'Enable', 'off');
            set(gui.displaycolortracetext, 'Enable', 'off');
            set(gui.displaycolortrace, 'Enable', 'off');
        elseif displaytracehow == CONST_GUI_TRACE_HOW_MEAN
            set(gui.displayerrorwhat, 'Enable', 'on');
            set(gui.displaycolortracetext, 'Enable', 'on');
            set(gui.displaycolortrace, 'Enable', 'on');
        end
        if ~strcmpi(get(gui.displayerrorwhat, 'Enable'), 'on') || displayerrorwhat == CONST_GUI_ERROR_WHAT_NOTHING %not drawing errors
            set(gui.displayerrorhow, 'Enable', 'off');
            set(gui.displaycolorerrortext, 'Enable', 'off');
            set(gui.displaycolorerror, 'Enable', 'off');
        else
            set(gui.displayerrorhow, 'Enable', 'on');
            set(gui.displaycolorerrortext, 'Enable', 'on');
            set(gui.displaycolorerror, 'Enable', 'on');
        end
        if displayxstyle == CONST_GUI_SCALE_AUTO
            set(gui.displayxmin, 'Enable', 'off');
            set(gui.displayxmax, 'Enable', 'off');
        else
            set(gui.displayxmin, 'Enable', 'on');
            set(gui.displayxmax, 'Enable', 'on');
        end
        if displayystyle == CONST_GUI_SCALE_AUTO
            set(gui.displayymin, 'Enable', 'off');
            set(gui.displayymax, 'Enable', 'off');
        else
            set(gui.displayymin, 'Enable', 'on');
            set(gui.displayymax, 'Enable', 'on');
        end
        if duringframeshow == CONST_GUI_IRRELEVANT
            set(gui.duringframes, 'Enable', 'off');
        else
            set(gui.duringframes, 'Enable', 'on');
        end
        if alignwhat == CONST_GUI_ALIGN_WHAT_SPEED || alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY || alignwhat == CONST_GUI_ALIGN_WHAT_OXYGEN
            set(gui.alignhow, 'Enable', 'off');
            set(gui.aligntoframetext, 'Enable', 'off');
            set(gui.aligntoframe, 'Enable', 'off');
        else
            set(gui.alignhow, 'Enable', 'on');
            set(gui.aligntoframetext, 'Enable', 'on');
            set(gui.aligntoframe, 'Enable', 'on');
        end
        if alignwhat == CONST_GUI_ALIGN_WHAT_SPEED || alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY
            set(gui.speedbinstext, 'Enable', 'on');
            set(gui.speedbins, 'Enable', 'on');
        else
            set(gui.speedbinstext, 'Enable', 'off');
            set(gui.speedbins, 'Enable', 'off');
        end
    end
    
    function clearplot (hobj, eventdata) %#ok<INUSD>
        axes(gui.mainimage);
        cla;
        if isdefaultcolor(colortrace)
            colortrace = CONST_GUI_COLORDEFAULTS{1};
            set(gui.displaycolortrace, 'String', colortrace);
        end
        if isdefaultcolor(colorerror)
            colorerror = CONST_GUI_COLORDEFAULTS{1};
            set(gui.displaycolorerror, 'String', colorerror);
        end
        legendnames = {};
        legendtraces = {};
        checkfigure;
    end

    function displaylegend(wheretodisplay)
        %unfortunately, legend seems kinda buggy and does not behave nicely in combination with copyobj,
        %so we will not copy the legend, but instead recreate it using this function where necessary
        if exist('wheretodisplay', 'var') ~= 1
            wheretodisplay = gui.mainimage;
        end
        
        if legendwhere ~= CONST_GUI_LEGEND_NO
            switch legendwhere
                case CONST_GUI_LEGEND_NORTHEAST
                    wheretoshow = 'NorthEast';
                case CONST_GUI_LEGEND_NORTHWEST
                    wheretoshow = 'NorthWest';
                case CONST_GUI_LEGEND_SOUTHEAST
                    wheretoshow = 'SouthEast';
                case CONST_GUI_LEGEND_SOUTHWEST
                    wheretoshow = 'SouthWest';
                case CONST_GUI_LEGEND_AUTO
                    wheretoshow = 'Best';
                otherwise
                    wheretoshow = 'BestOutside';
            end
            warning('off', 'MATLAB:legend:PlotEmpty'); %we don't care about this
            legend(wheretodisplay, horzcat(legendtraces{:}), legendnames, 'Location', wheretoshow);
            legend(wheretodisplay, 'boxoff');
            warning('on', 'MATLAB:legend:PlotEmpty');
        else
            legend('off');
        end
    end

    function popupfigure (hobj, eventdata) %#ok<INUSD>
        newfigure = figure;
        newaxes = copyobj(gui.mainimage, newfigure);
        displaylegend(newaxes); %legend does not seem to be copied along with the axes, so we'll have to recreate it
    end

    function export(hobj, eventdata) %#ok<INUSD>
        
    end
    
    function varargout = plotit (hobj, eventdata) %#ok<INUSD>
        
        if numel(objects) == 0
            questdlg('No objects recognised. You must first read data files in order to plot their results.', 'Plotting', 'OK', 'OK');
            return
        end
        
        if nargout == 0
            set(gui.plotit, 'String', 'Adding to plot...');
            drawnow;
        
            axes(gui.mainimage);
            hold on;
        end
        
        cancelledframerate = false;
        setallunknownframeratesto = NaN;
        setallunknownframerates = CONST_GUI_UNKNOWN;
        
        
        %a = load('avbaiyfilenames'); %CHANGEME
        usableobjects = true(1, numel(objects));
        for i=1:numel(objects)
            if ~ismember(objects(i).regionname, selectedregions) %don't look at it if it's not a region we're interested in (region must be one of those selected by the user)
                usableobjects(i) = false;
            end
            %CHANGEMEFROM
            %{
            if any(ismember(selectedregions, {'AVB  ', 'AIY  '}))
                if strcmp(objects(i).regionname, 'AVB  ')
                    whereAVB = cellfun(@(s) (strcmp(s, objects(i).filenames{1})), a.filenames);
                    if isnan(a.avbwhere(whereAVB))
                        usableobjects(i) = false;
                    end
                end
                if strcmp(objects(i).regionname, 'AIY  ')
                    whereAIY = cellfun(@(s) (strcmp(s, objects(i).filenames{1})), a.filenames);
                    if isnan(a.aiywhere(whereAIY))
                        usableobjects(i) = false;
                    end
                end
            end
            %CHANGEMEUNTIL
            %}
        end
        
        if numel(colortrace) > 1
            colortracetouse = string2matrix(colortrace, {' ', ',', ';', '[', ']'});
        else
            colortracetouse = colortrace;
        end
        if numel(colorerror) > 1
            colorerrortouse = string2matrix(colorerror, {' ', ',', ';', '[', ']'});
        else
            colorerrortouse = colorerror;
        end
        
        for i=1:numel(objects)
            
            if ~usableobjects(i)
                continue;
            end
            
            if ~strcmp(objects(i).regionname, CONST_TRACKER_REGIONNAME)
                
                framedifference = max([1, round(speedover/objects(i).deltatime)]);
                timedifference = framedifference * objects(i).deltatime; %converting back so that we preserve the potential small change introduced by the rounding to integer frame values in the previous step
                dx = [NaN(1, framedifference) objects(i).absx(1+framedifference:end)-objects(i).absx(1:end-framedifference)];
                dy = [NaN(1, framedifference) objects(i).absy(1+framedifference:end)-objects(i).absy(1:end-framedifference)];
                objects(i).speed = hypot(dx, dy)/timedifference;

                objects(i).velocity = objects(i).speed;
                velocitynegative = objects(i).behaviour == CONST_BEHAVIOUR_NEURON_REVERSAL;
                velocitynan = objects(i).behaviour ~= CONST_BEHAVIOUR_NEURON_FORWARDS & objects(i).behaviour ~= CONST_BEHAVIOUR_NEURON_REVERSAL;
                objects(i).velocity(velocitynegative) = -objects(i).velocity(velocitynegative);
                objects(i).velocity(velocitynan) = NaN;

                objects(i).direction = NaN(1, numel(objects(i).behaviour));
                objects(i).direction(objects(i).behaviour == CONST_BEHAVIOUR_NEURON_FORWARDS) = 1;
                objects(i).direction(objects(i).behaviour == CONST_BEHAVIOUR_NEURON_STATIONARY) = 0;
                objects(i).direction(objects(i).behaviour == CONST_BEHAVIOUR_NEURON_REVERSAL) = -1;

                objects(i).reversal = NaN(1, numel(objects(i).behaviour));
                objects(i).reversal(objects(i).behaviour == CONST_BEHAVIOUR_NEURON_REVERSAL) = 1;
                objects(i).reversal(objects(i).behaviour == CONST_BEHAVIOUR_NEURON_FORWARDS) = 0;

                currentrevstarts = NaN(1, numel(objects(i).behaviour));
                currentrevinitlist = strfind(objects(i).reversal, [0 1])+1;
                currentrevnoinitlist = strfind(objects(i).reversal, [0 0])+1;
                currentrevstarts(currentrevinitlist) = 1;
                currentrevstarts(currentrevnoinitlist) = 0;
                objects(i).revinit = currentrevstarts;
                
                currentrevdurs = NaN(1, numel(objects(i).behaviour));
                for j=1:numel(currentrevinitlist)
                    frameindex = currentrevinitlist(j);
                    while frameindex <= numel(objects(i).behaviour)
                        if isnan(objects(i).reversal(frameindex))
                            break;
                        elseif objects(i).reversal(frameindex) == 0
                            currentrevdurs(currentrevinitlist(j)) = frameindex - currentrevinitlist(j);
                            break;
                        elseif objects(i).reversal(frameindex) == 1
                            frameindex = frameindex + 1;
                        else
                            error('unknown reversal flag');
                        end
                    end
                end
                objects(i).revdur = currentrevdurs;
            end
        end
        
        if displaytracewhat == CONST_GUI_TRACE_WHAT_SPEED
            valuestouse = {objects(usableobjects).speed};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_VELOCITY
            valuestouse = {objects(usableobjects).velocity};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_DIRECTION
            valuestouse = {objects(usableobjects).direction};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVERSALS
            valuestouse = {objects(usableobjects).reversal};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVINIT
            valuestouse = {objects(usableobjects).revinit};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVDUR
            valuestouse = {objects(usableobjects).revdur};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_OMEGAS
            valuestouse = {objects(usableobjects).omegas};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_SPECTRALDENSITY
            valuestouse = {objects(usableobjects).spectraldensityP};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_RATIO
            valuestouse = {objects(usableobjects).ratios};
            if deltaroverr
                for i=1:numel(valuestouse)
                    valuestouse{i} = converttodeltar(valuestouse{i});
                end
            end
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_NSPEED
            valuestouse = {objects(usableobjects).speed};
            valuessum = zeros(1, max(cellfun(@numel, valuestouse)));
            for i=1:numel(valuestouse)
                valuessum(1:numel(valuestouse{i})) = valuessum(1:numel(valuestouse{i})) + double(~isnan(valuestouse{i}));
            end
            valuestouse = {valuessum};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_NREV
            valuestouse = {objects(usableobjects).reversal};
            valuessum = zeros(1, max(cellfun(@numel, valuestouse)));
            for i=1:numel(valuestouse)
                valuessum(1:numel(valuestouse{i})) = valuessum(1:numel(valuestouse{i})) + double(~isnan(valuestouse{i}));
            end
            valuestouse = {valuessum};
        elseif displaytracewhat == CONST_GUI_TRACE_WHAT_NRATIO
            valuestouse = {objects(usableobjects).ratios}; %will be changed into n later after filtering
        end
        valuestoobjectids = find(usableobjects);
        
        %Compensating for nonconstant framerate AstroIIDC or FlyCap movies, if necessary
        if ~isempty(valuestoobjectids) && strcmp(objects(valuestoobjectids(1)).regionname, CONST_TRACKER_REGIONNAME) && (displaytracewhat == CONST_GUI_TRACE_WHAT_SPEED || displaytracewhat == CONST_GUI_TRACE_WHAT_VELOCITY)
            
            compensation(1).name = '15/2';
            compensation(1).every = 8;
            compensation(1).multiplier = (1)/1*2;
            compensation(2).name = '7.5/2';
            compensation(2).every = 4;
            compensation(2).multiplier = (1)/1.5*2;
            %compensation(3).name = '3.75/2';
            %compensation(3).every = 2;
            %compensation(3).multiplier = (1)/1.75*2;
            
            for i=1:numel(valuestouse)
                valuestouseoriginal = valuestouse{i};
                compensatedvaluestouse = NaN(numel(compensation), numel(valuestouseoriginal));
                compensateddiffimprovement = NaN(1, numel(compensation));
                compensatedcorrimprovement = NaN(1, numel(compensation));
                for j=1:numel(compensation)
                    
                    wherecompensatenow = 1+compensation(j).every:compensation(j).every:numel(valuestouseoriginal);
                    
                    compensatedvaluestouse(j, :) = valuestouseoriginal;
                    compensatedvaluestouse(j, wherecompensatenow) = compensatedvaluestouse(j, wherecompensatenow)*compensation(j).multiplier;
                    
                    newy = compensatedvaluestouse(j, :);
                    newy = newy(~isnan(newy));
                    oldy = valuestouseoriginal(~isnan(valuestouseoriginal));
                    
                    gotcorrs = false;
                    if license('checkout', 'Statistics_Toolbox') || license('test', 'Statistics_Toolbox') %if we're already using the statistics toolbox, or if we could use it
                        try %#ok<TRYNC>
                            oldcorr = corr(oldy(1+compensation(j).every:end)', oldy(1:end-compensation(j).every)');
                            newcorr = corr(newy(1+compensation(j).every:end)', newy(1:end-compensation(j).every)');
                            gotcorrs = true;
                        end
                    end
                    if ~gotcorrs %without the statistics toolbox (or if it failed), doing it a bit more roundabout way
                        Rold = corrcoef(oldy(1+compensation(j).every:end)', oldy(1:end-compensation(j).every)');
                        Rnew = corrcoef(newy(1+compensation(j).every:end)', newy(1:end-compensation(j).every)');
                        oldcorr = Rold(1, 2);
                        newcorr = Rnew(1, 2);
                    end
                    
                    compensateddiffimprovement(j) = sum(diff(oldy).^2) - sum(diff(newy).^2); %reducing the jumpiness of the trace is an improvement
                    compensatedcorrimprovement(j) = oldcorr - newcorr; %reducing lagged autocorrelation is an improvement
                end
                
                [maxdiffvalue, maxdiffindex] = max(compensateddiffimprovement);
                [maxcorrvalue, maxcorrindex] = max(compensatedcorrimprovement);
                
                whichcompensation = NaN;
                clearlydetected = false;
                
                %the order in which these are checked is important (first the more reliable combinations)
                if maxdiffindex == maxcorrindex && (maxdiffvalue > 0 || maxcorrvalue > 0) %if the two methods agree, then it's trivial
                    whichcompensation = maxdiffindex;
                    if maxdiffvalue > 0 && maxcorrvalue > 0
                        clearlydetected = true;
                    end
                elseif compensatedcorrimprovement(maxdiffindex) > 0 %if using the best option with one method also results in an improvement with the another, then use it
                    whichcompensation = maxdiffindex;
                elseif compensateddiffimprovement(maxcorrindex) > 0 %if using the best option with one method also results in an improvement with the another, then use it
                    whichcompensation = maxcorrindex;
                elseif maxdiffvalue > 0 && maxcorrvalue <= 0 %if only one of the methods could find an improvement, use it
                    whichcompensation = maxdiffindex;
                elseif maxcorrvalue > 0 && maxdiffvalue <= 0 %if only one of the methods could find an improvement, use it
                    whichcompensation = maxcorrindex;
                elseif maxdiffindex ~= maxcorrindex && maxdiffvalue > 0 && maxcorrvalue > 0 %if both methods found improvements, but with different options, then we have a disagreement
                    fprintf('Warning: detected an ambiguous pattern of recording framerate aberration in movie %d. Not knowing how to compensate, keeping the data as is...\n', i);
                end
                
                if ~isnan(whichcompensation)
                    if clearlydetected
                        fprintf('Clearly d');
                    else
                        fprintf('D');
                    end
                    fprintf('etected a %s pattern of recording framerate aberration in movie %d . Compensating...\n', compensation(whichcompensation).name, i);
                    valuestouse{i} = compensatedvaluestouse(whichcompensation, :);
                end
                
            end
        end
        
        %light flash-based alignment
        if alignwhat == CONST_GUI_ALIGN_WHAT_LIGHT
            for i=1:numel(valuestouse)
                currentflashindex = objects(valuestoobjectids(i)).flashindices;
                if numel(currentflashindex) >= 1 && ~isnan(currentflashindex(1))
                    if alignhow == CONST_GUI_ALIGN_HOW_START
                        valuestouse{i} = valuestouse{i}(currentflashindex(1):end);
                    elseif alignhow == CONST_GUI_ALIGN_HOW_END
                        valuestouse{i} = valuestouse{i}(1:currentflashindex(end));
                    end
                end
            end
        end
        
        %binning (and the ability to combine results from movies with different framerates)
        if ~isnan(binning) && binning ~= 0
            if alignwhat == CONST_GUI_ALIGN_WHAT_SPEED || alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY || alignwhat == CONST_GUI_ALIGN_WHAT_OXYGEN
                questdlg('Warning: speed, velocity, or oxygen-based alignments do not work in combination with binning. Disable one or the other.','Plotting results', 'OK', 'OK');
                set(gui.plotit, 'String', 'Add to plot');
                checkfigure;
                return
            end
            for i=1:numel(valuestouse)
                currentframerate = objects(valuestoobjectids(i)).framerate;
                if isempty(currentframerate) || isnan(currentframerate) || currentframerate ==  0
                    currentframerate = 1/objects(valuestoobjectids(i)).deltatime;
                end
                if ~cancelledframerate
                    if isempty(currentframerate) || isnan(currentframerate) || currentframerate ==  0
                        newframerate = [];
                        if ~isnan(setallunknownframeratesto)
                            if setallunknownframerates == CONST_GUI_UNKNOWN
                                if strcmp(questdlg(sprintf('Assume a framerate of %f for all remaining movies with unknown framerates? (this framerate will NOT be saved into the analysis file - re-reading the data will reset it)', setallunknownframeratesto),'Setting framerate','Assume the same framerate','Enter framerates individually','Assume the same framerate'),'Assume the same framerate')
                                    setallunknownframerates = CONST_GUI_YES;
                                else
                                    setallunknownframerates = CONST_GUI_NO;
                                end
                            end
                            if setallunknownframerates == CONST_GUI_YES
                                newframerate = setallunknownframeratesto;
                            end
                        end
                        while isempty(newframerate)
                            newframerates = inputdlg(sprintf('Unknown framerate for %s. Enter framerate (this framerate will NOT be saved into the analysis file - re-reading the data will reset it):', objects(valuestoobjectids(i)).filenames{1}), 'Specify the framerate');
                            if iscell(newframerates) && isempty(newframerates)
                                cancelledframerate = true;
                                break
                            end
                            newframerate = str2double(char(newframerates));
                            if isnan(newframerate) || newframerate == 0
                                newframerate = [];
                            end
                        end
                        if ~cancelledframerate
                            objects(valuestoobjectids(i)).framerate = newframerate;
                            currentframerate = newframerate;
                            setallunknownframeratesto = currentframerate;
                        end
                    end
                end
                if ~cancelledframerate
                    combinehowmany = currentframerate*binning;
                    currentvaluesbinned = NaN(1, floor(numel(valuestouse{i})/combinehowmany));
                    currentlyfinished = 1; %how much frames have been completely "used up" (in terms of converting into a binned (potentially weighted) mean). can be a fraction, representing how much of its weight has been "used up".
                    binnedindex = 1;
                    while true
                        currentweights = zeros(1, numel(valuestouse{i}));
                        weightsremaining = combinehowmany;
                        while weightsremaining > 0
                            whichonetoadd = floor(currentlyfinished);
                            if floor(currentlyfinished) == currentlyfinished
                                howmuchtoadd = 1;
                            else
                                howmuchtoadd = ceil(currentlyfinished) - currentlyfinished;
                            end
                            if howmuchtoadd > weightsremaining
                                howmuchtoadd = weightsremaining;
                            end
                            if whichonetoadd > numel(valuestouse{i}) %don't use the last bin if it would be partial
                                currentweights = zeros(1, numel(valuestouse{i}));
                                break;
                            end
                            currentweights(whichonetoadd) = currentweights(whichonetoadd) + howmuchtoadd;
                            weightsremaining = weightsremaining - howmuchtoadd;
                            currentlyfinished = currentlyfinished + howmuchtoadd;
                        end
                        if any(currentweights)
                            currentvaluesbinned(binnedindex) = nanwmean(valuestouse{i}(currentweights>0), currentweights(currentweights>0));
                            binnedindex = binnedindex + 1;
                        else
                            break
                        end
                    end
                    valuestouse{i} = currentvaluesbinned;
                else
                    valuestouse{i} = NaN;
                end
            end
        end
        
        
        %filtering according to speed, individual values thresholds and the oxygen levels
        if ~isnan(binning) && binning ~= 0 && ((~isnan(speedmin) && ~isinf(speedmin)) || (~isnan(speedmax) && ~isinf(speedmax)))
            questdlg('Warning: speed thresholds do not work in combination with binning. Disable one or the other.','Plotting results', 'OK', 'OK');
            set(gui.plotit, 'String', 'Add to plot');
            checkfigure;
            return
        end
        if displaytracewhat == CONST_GUI_TRACE_WHAT_REVINIT && ~isnan(binning) && binning ~= 0 && ((~isnan(valuesmin) && ~isinf(valuesmin) && valuesmin ~= 0) || (~isnan(valuesmax) && ~isinf(valuesmax)))
            questdlg('Warning: reversal duration thresholds do not work in combination with binning. Disable one or the other.','Plotting results', 'OK', 'OK');
            set(gui.plotit, 'String', 'Add to plot');
            checkfigure;
            return
        end
        for i=1:numel(valuestouse)
            if isempty(valuestouse{i})
                continue
            end
            if (isnan(binning) || binning == 0) && alignwhat ~= CONST_GUI_ALIGN_WHAT_LIGHT
                clearratioswhere = objects(valuestoobjectids(i)).speed < speedmin | objects(valuestoobjectids(i)).speed > speedmax ... %if a thresholds are NaN, they will not be flagged for clearing
                | ~ismember(objects(valuestoobjectids(i)).oxygen, selectedoxygens);
                if numel(valuestouse{i}) < numel(clearratioswhere)
                    clearratioswhere = false(1, numel(valuestouse{i}));
                end
            else
                clearratioswhere = false(1, numel(valuestouse{i}));
            end
            if displaytracewhat == CONST_GUI_TRACE_WHAT_REVINIT
                if ((~isnan(valuesmin) && ~isinf(valuesmin) && valuesmin ~= 0) || (~isnan(valuesmax) && ~isinf(valuesmax)))
                    clearratioswhere = clearratioswhere | objects(valuestoobjectids(i)).revdur < valuesmin | objects(valuestoobjectids(i)).revdur > valuesmax;
                end
            elseif displaytracewhat ~= CONST_GUI_TRACE_WHAT_NSPEED && displaytracewhat ~= CONST_GUI_TRACE_WHAT_NREV && displaytracewhat ~= CONST_GUI_TRACE_WHAT_NRATIO
                clearratioswhere = clearratioswhere | valuestouse{i} < valuesmin | valuestouse{i} > valuesmax;
            end
            valuestouse{i}(clearratioswhere) = NaN;
        end
        
        %Filtering multiple objects from the same worm when plotting some kind of behaviour
        %When we're plotting something that's about the worm (e.g. reversals or speed), rather than the neurons (ratios), only one region should appear from each movie (otherwise it's pseudoreplication).
        %It's the region with the most valid values that should remain when we have multiple regions from the same movies.
        %We should keep the speed values for each region when we're plotting ratios so that we can match the region ratios with the same region speed
        if displaytracewhat == CONST_GUI_TRACE_WHAT_SPEED || displaytracewhat == CONST_GUI_TRACE_WHAT_VELOCITY || displaytracewhat == CONST_GUI_TRACE_WHAT_DIRECTION || displaytracewhat == CONST_GUI_TRACE_WHAT_REVERSALS || displaytracewhat == CONST_GUI_TRACE_WHAT_REVINIT || displaytracewhat == CONST_GUI_TRACE_WHAT_REVDUR || displaytracewhat == CONST_GUI_TRACE_WHAT_OMEGAS
            recheck = true;
            while recheck
                recheck = false;
                for i=1:numel(valuestoobjectids)
                    longestusablelength = sum(~isnan(valuestouse{i}));
                    longestusablewhich = i;
                    sameworm = i;
                    for j=i+1:numel(valuestoobjectids)
                        if any(ismember(objects(valuestoobjectids(i)).filenames, objects(valuestoobjectids(j)).filenames))
                            sameworm(end+1) = j; %#ok<AGROW>
                            currentusablelength = sum(~isnan(valuestouse{j}));
                            if currentusablelength > longestusablelength
                                longestusablelength = currentusablelength;
                                longestusablewhich = j;
                            end
                        end
                    end
                    if numel(sameworm) > 1
                        recheck = true;
                        keepvalues = true(1, numel(valuestouse));
                        keepvalues(sameworm) = false;
                        if longestusablelength > 0
                            keepvalues(longestusablewhich) = true;
                        end
                        valuestouse = valuestouse(keepvalues);
                        valuestoobjectids = valuestoobjectids(keepvalues);
                        break;
                    end
                end
            end
        end
        
        extracted = struct('values', [], 'speeds', [], 'velocities', [], 'oxygen', [], 'objectids', [], 'tracestartabs', [], 'extractedtraceendabs', [], 'extractedbehaviourstartrel', [], 'extractedbehaviourendrel', []);
        extractedn = 0;
        
        for valuesindex=1:numel(valuestouse)
            if ~any(~isnan(valuestouse{valuesindex})) %don't even look at it if it doesn't have any valid values
                continue;
            end
            
            currentfirstframe = max([1, fromframe]);
            currentlastframe = min([numel(valuestouse{valuesindex}), untilframe]);
            
            for frameindex = currentfirstframe:currentlastframe
                
                beforeindex = frameindex - 1;
                
                if beforeindex < currentfirstframe
                    beforeok = beforeoutside;
                else
                    beforeok = xor(wantedbehaviour(valuestoobjectids(valuesindex), beforeindex, beforebehaviour), beforeyes == CONST_GUI_NO);
                end
                if ~beforeok
                    continue;
                end
                
                duringstartok = xor(wantedbehaviour(valuestoobjectids(valuesindex), frameindex, duringbehaviour), duringyes == CONST_GUI_NO);
                if ~duringstartok
                    continue;
                end
                duringbehaviourstartindex = frameindex;
                
                duringbehaviourendindex = NaN;
                for forwardscheckindex = frameindex+1 : currentlastframe+1
                    if forwardscheckindex <= currentlastframe
                        if ~(xor(wantedbehaviour(valuestoobjectids(valuesindex), forwardscheckindex, duringbehaviour), duringyes == CONST_GUI_NO)) %if it's not the one behaviour we expect
                            duringbehaviourendindex = forwardscheckindex - 1;
                            break;
                        end
                    else
                        if afteroutside
                            duringbehaviourendindex = forwardscheckindex - 1;
                            break;
                        end
                    end
                end
                if isnan(duringbehaviourendindex)
                    continue;
                end

                beforebehaviourstartindex = NaN;
                for backwardscheckindex = beforeindex : -1 : currentfirstframe-1
                    if backwardscheckindex >= currentfirstframe
                        if ~(xor(wantedbehaviour(valuestoobjectids(valuesindex), backwardscheckindex, beforebehaviour), beforeyes == CONST_GUI_NO)) %if it's not the one behaviour we expect
                            beforebehaviourstartindex = backwardscheckindex + 1;
                            break;
                        end
                    else
                        if beforeoutside
                            beforebehaviourstartindex = backwardscheckindex + 1;
                            break;
                        end
                    end
                end
                if isnan(beforebehaviourstartindex)
                    continue;
                end
                
                afterbehaviourendindex = NaN;
                for forwardscheckindex = duringbehaviourendindex+1 : currentlastframe+1
                    if forwardscheckindex <= currentlastframe
                        if ~(xor(wantedbehaviour(valuestoobjectids(valuesindex), forwardscheckindex, afterbehaviour), afteryes == CONST_GUI_NO)) %if it's not the one behaviour we expect
                            afterbehaviourendindex = forwardscheckindex - 1;
                            break;
                        end
                    else
                        if afteroutside
                            afterbehaviourendindex = forwardscheckindex - 1;
                            break;
                        end
                    end
                end
                if isnan(afterbehaviourendindex)
                    continue;
                end
                
                numelbeforeframes = duringbehaviourstartindex-beforebehaviourstartindex;
                numelduringframes = duringbehaviourendindex-duringbehaviourstartindex+1;
                numelafterframes = afterbehaviourendindex-duringbehaviourendindex;

                if ~(duringframeshow == CONST_GUI_IRRELEVANT ...
                    || (duringframeshow == CONST_GUI_ATLEAST && numelduringframes >= duringframes) ...
                    || (duringframeshow == CONST_GUI_ATMOST && numelduringframes <= duringframes))
                    continue;
                end

                if numelbeforeframes < beforeframes
                    continue;
                end

                if numelafterframes < afterframes
                    continue;
                end
                
                currentbehaviourstart = 1;
                currentbehaviourend = numelduringframes;
                if beforeincluded
                    currentfromindex = beforebehaviourstartindex;
                    currentbehaviourstart = currentbehaviourstart + numelbeforeframes;
                    currentbehaviourend = currentbehaviourend + numelbeforeframes;
                else
                    currentfromindex = duringbehaviourstartindex;
                end
                
                if afterincluded
                    currentuntilindex = afterbehaviourendindex;
                else
                    currentuntilindex = duringbehaviourendindex;
                end
                
                currentvalues = valuestouse{valuesindex}(currentfromindex:currentuntilindex);
                currentobjectid = valuestoobjectids(valuesindex);
                
                if any(~isnan(currentvalues))
                    extractedn = extractedn+1;
                    extracted(extractedn).values = currentvalues;
                    extracted(extractedn).objectids = ones(1, numel(currentvalues))*currentobjectid;
                    if numel(currentvalues) == numel(objects(currentobjectid).speed) %if no binning or light-based alignment had been done %CHANGEME: THIS IS OLD CODE I AM UNSURE ABOUT
                        extracted(extractedn).speeds = objects(currentobjectid).speed(currentfromindex:currentuntilindex);
                        extracted(extractedn).velocities = objects(currentobjectid).velocity(currentfromindex:currentuntilindex);
                    end
                    if displaytracewhat ~= CONST_GUI_TRACE_WHAT_NSPEED && displaytracewhat ~= CONST_GUI_TRACE_WHAT_NREV && displaytracewhat ~= CONST_GUI_TRACE_WHAT_NRATIO
                        extracted(extractedn).oxygen = objects(currentobjectid).oxygen(currentfromindex:currentuntilindex);
                    end
                    extracted(extractedn).tracestartabs = beforebehaviourstartindex;
                    extracted(extractedn).behaviourstartrel = currentbehaviourstart;
                    extracted(extractedn).behaviourendrel = currentbehaviourend;
                    extracted(extractedn).traceendabs = afterbehaviourendindex;
                end
                
            end
        end
        
        %CHANGEME
        %for i=1:numel(extracted)
        %    extracted(i).values(1:min(numel(extracted(i).values), 250)) = NaN;
        %end
        %CHANGEME
        
        %ALIGNMENT
        alignwhichframe = NaN;
        for i=1:extractedn
            if alignwhat == CONST_GUI_ALIGN_WHAT_NOTHING
                if alignhow == CONST_GUI_ALIGN_HOW_START
                    alignwhichframe = 1;
                    addnan = NaN(1, extracted(i).tracestartabs-1);
                elseif alignhow == CONST_GUI_ALIGN_HOW_END
                    alignwhichframe = max(vertcat(extracted.traceendabs));
                    addnan = NaN(1, alignwhichframe-extracted(i).traceendabs);
                else
                    error('unknown alignhow');
                end
            elseif alignwhat == CONST_GUI_ALIGN_WHAT_INTERVALS 
                if alignhow == CONST_GUI_ALIGN_HOW_START
                    alignwhichframe = 1;
                    break;
                elseif alignhow == CONST_GUI_ALIGN_HOW_END
                    alignwhichframe = max(arrayfun(@(x)numel(x.values),extracted));
                    if isempty(alignwhichframe), alignwhichframe = 0; end
                    addnan = NaN(1, alignwhichframe-numel(extracted(i).values));
                else
                    error('unknown alignhow');
                end
            elseif alignwhat == CONST_GUI_ALIGN_WHAT_BEHAVIOUR
                if alignhow == CONST_GUI_ALIGN_HOW_START
                    alignwhichframe = max(vertcat(extracted.behaviourstartrel));
                    addnan = NaN(1, alignwhichframe-extracted(i).behaviourstartrel);
                elseif alignhow == CONST_GUI_ALIGN_HOW_END
                    alignwhichframe = max(vertcat(extracted.behaviourendrel));
                    addnan = NaN(1, alignwhichframe-extracted(i).behaviourendrel);
                else
                    error('unknown alignhow');
                end
            elseif alignwhat == CONST_GUI_ALIGN_WHAT_SPEED || alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY || alignwhat == CONST_GUI_ALIGN_WHAT_OXYGEN
                alignwhichframe = NaN;
                break; %then we're not aligning them like this
            elseif alignwhat == CONST_GUI_ALIGN_WHAT_LIGHT
                %this has already been taken care of
                alignwhichframe = NaN; 
                break; %we don't need to align anything
            else
                error('unknown alignwhat');
            end
            extracted(i).values = [addnan extracted(i).values];
            extracted(i).speeds = [addnan extracted(i).speeds];
            extracted(i).velocities = [addnan extracted(i).velocities];
            extracted(i).oxygen = [addnan extracted(i).oxygen];
            extracted(i).objectids = [addnan extracted(i).objectids];
        end
                
        %moving averages
        if movingaveragevalue > 1
            for i=1:extractedn
                extracted(i).values = movingaveragefilterwithoutnan(extracted(i).values, movingaveragevalue);
            end
        end
        if movingaveragespeed > 1
            for i=1:extractedn
                extracted(i).speeds = movingaveragefilterwithoutnan(extracted(i).speeds, movingaveragespeed);
            end
        end
        
        if displaytracewhat == CONST_GUI_TRACE_WHAT_NRATIO
            currentextractedvalues = {extracted.values};
            
            if isempty(currentextractedvalues) || (numel(currentextractedvalues) == 1 && isempty(currentextractedvalues{1}))
                questdlg('No ratio data was found, therefore there is nothing to plot with these settings.', 'Plotting', 'OK', 'OK');
                set(gui.plotit, 'String', 'Add to plot');
                checkfigure;
                return
            end
            
            maxobjid = -Inf;
            for i=1:numel(extracted)
                currentobjids = extracted(i).objectids;
                currentobjectid = mean(currentobjids(~isnan(currentobjids)));
                if currentobjectid > maxobjid
                    maxobjid = currentobjectid;
                end
            end
            
            wherethereisdata = zeros(maxobjid, max(cellfun(@numel, currentextractedvalues)));
            
            for i=1:numel(extracted)
                currentobjids = extracted(i).objectids;
                currentobjectid = mean(currentobjids(~isnan(currentobjids)));
                wherethereisdata(currentobjectid, 1:numel(currentextractedvalues{i})) = wherethereisdata(currentobjectid, 1:numel(currentextractedvalues{i})) | double(~isnan(currentextractedvalues{i}));
            end
            
            clear extracted
            extracted(1).values = sum(wherethereisdata, 1);
            
            %{
            valuessum = zeros(1, max(cellfun(@numel, currentextractedvalues)));
            for i=1:numel(currentextractedvalues)
                valuessum(1:numel(currentextractedvalues{i})) = valuessum(1:numel(currentextractedvalues{i})) + double(~isnan(currentextractedvalues{i}));
            end
            clear extracted
            extracted(1).values = valuessum;
            %}
        end
        
        %Setting up strings to show what attribute was extracted.
        %This value may be used in the legends, in speed correlation messages, and in the error message when nothing can be displayed
        switch displaytracewhat
            case CONST_GUI_TRACE_WHAT_RATIO
                extractedstring = 'ratio';
            case CONST_GUI_TRACE_WHAT_SPEED
                extractedstring = 'speed';
            case CONST_GUI_TRACE_WHAT_VELOCITY
                extractedstring = 'velocity';
            case CONST_GUI_TRACE_WHAT_DIRECTION
                extractedstring = 'direction';
            case CONST_GUI_TRACE_WHAT_REVERSALS
                extractedstring = 'reversal proportion';
            case CONST_GUI_TRACE_WHAT_REVINIT
                extractedstring = 'reversal initiation chance';
            case CONST_GUI_TRACE_WHAT_REVDUR
                extractedstring = 'reversal duration';
            case CONST_GUI_TRACE_WHAT_OMEGAS
                extractedstring = 'omega proportion';
            case CONST_GUI_TRACE_WHAT_SPECTRALDENSITY
                extractedstring = 'spectral density';
            otherwise
                extractedstring = 'extracted';
        end
        
        currentlegendname = '';
        displayedregionname = '';
        for i=1:numel(selectedregions)
            currentname = strtrim(selectedregions{i});
            if i>1
                currentname = ['+' currentname]; %#ok<AGROW>
            end
            currentlegendname(end+1:end+numel(currentname)) = currentname;
            displayedregionname = currentlegendname; %used in the speed correlation message later
        end
        
        if strcmp(currentlegendname, CONST_TRACKER_REGIONNAME)
            currentlegendname = extractedstring;
        end
        
        %Binned alignment
        binnumbers = NaN;
        if alignwhat == CONST_GUI_ALIGN_WHAT_SPEED || alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY || alignwhat == CONST_GUI_ALIGN_WHAT_OXYGEN
            alignvalues = horzcat(extracted.values);
            alignids = horzcat(extracted.objectids);
            if alignwhat == CONST_GUI_ALIGN_WHAT_SPEED
                alignby = horzcat(extracted.speeds);
            elseif alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY
                alignby = horzcat(extracted.velocities);
            elseif alignwhat == CONST_GUI_ALIGN_WHAT_OXYGEN
                alignby = horzcat(extracted.oxygen);
            else
                error('unknown alignwhat');
            end
            
            alignvalid = ~isnan(alignvalues) & ~isnan(alignby);
            
            %CHANGEME: CHECK THAT NORMALIZATION WORKS FOR THE DIFFERENT PLOTTING METHODS
            %{
            if normalize
                alignvalues = (alignvalues - mean(alignvalues(alignvalid))) ./ std(alignvalues(alignvalid));
            end
            %}
            
            if alignwhat ~= CONST_GUI_ALIGN_WHAT_OXYGEN
                [R, P] = corrcoef(alignvalues(alignvalid), alignby(alignvalid));
                switch alignwhat
                    case CONST_GUI_ALIGN_WHAT_SPEED
                        correlatedwith = 'speed';
                    case CONST_GUI_ALIGN_WHAT_VELOCITY
                        correlatedwith = 'velocity';
                    otherwise
                        correlatedwith = 'something';
                end
                fprintf('The correlation between %s and %s %s values is R=%f (p=%e).\n', correlatedwith, displayedregionname, extractedstring, R(1, 2), P(1, 2));
                try
                    binnumbers = eval(speedbins);
                catch %#ok<CTCH>
                    binnumbers = NaN;
                    if strcmp(questdlg('Warning: the specified speed bins could not be interpreted as numbers. Proceed without speed binning?','Plotting results','Proceed','Cancel','Proceed'),'Cancel')
                        checkfigure;
                        return
                    end
                end
            else %oxygen
                binnumbers = [1 2 3 4 5 Inf];
            end
            
        end
        
        %if we can binalign it, then we do
        %this is separate from the previous binalign setup to be able to give the user the option to proceed without speed binning if speed bin eval runs into an error
        if numel(binnumbers)>1 && ~isnan(binnumbers(1)) 
            bins(numel(binnumbers)-1) = struct('valuemeans', [], 'bymeans', [], 'objectids', []);
            
            for i=1:numel(objects)
                if ~usableobjects(i)
                    continue;
                end
                currentvalues = alignvalues(alignids==i & alignvalid);
                currentby = alignby(alignids==i & alignvalid);
                if isempty(currentvalues) || isempty(currentby)
                    continue;
                end
                [n, intowhichbin] = histc(currentby, binnumbers);
                for binindex=1:numel(binnumbers)-1
                    currentvaluemean = mean(currentvalues(intowhichbin==binindex));
                    if ~isnan(currentvaluemean)
                        bins(binindex).valuemeans(end+1) = currentvaluemean;
                        bins(binindex).bymeans(end+1) = mean(currentby(intowhichbin==binindex));
                        bins(binindex).objectids(end+1) = i;
                    end
                end
            end
            
            xvalues = NaN(1, numel(binnumbers)-1);
            yvalues = NaN(max(cellfun(@length, {bins.valuemeans})), numel(binnumbers)-1);
            for binindex=1:numel(binnumbers)-1
                currentx = horzcat(bins(binindex).bymeans);
                xvalues(binindex) = mean(currentx(~isnan(currentx)));
                yvalues(1:numel(bins(binindex).valuemeans), binindex) = bins(binindex).valuemeans;
            end
            
            %yvalues(:, end) = NaN; %CHANGEME
            
            if normalize
                yvalues = (yvalues - mean(yvalues(~isnan(yvalues(:))))) / std(yvalues(~isnan(yvalues(:))));
            end
            
        else
            
            longestextracted = max(arrayfun(@(x)numel(x.values),extracted)); %we need to calculate longestextracted directly here because above the NaN padding for NOTHING alignment could have changed the number of elements
            if isempty(longestextracted)               
                xvalues = [];
                yvalues = [];
            else
                xvalues = (1:longestextracted)-alignwhichframe+aligntoframe;
                if all(isnan(xvalues))
                    xvalues = 1:numel(xvalues);
                end
                yvalues = {extracted.values};
                
                if normalize
                    referencevalues = [];
                    for i=1:numel(yvalues)
                        currentgood = ~isnan(yvalues{i});
                        if displayxstyle == CONST_GUI_SCALE_MANUAL
                            xgood = xvalues >= xmin & xvalues <= xmax; %we base the normalization on the x-values of interest
                            currentgood(~xgood(1:numel(currentgood))) = false;
                        end
                        referencevalues(end+1:end+sum(currentgood)) = yvalues{i}(currentgood);
                    end
                    for i=1:numel(yvalues)
                        yvalues{i} = (yvalues{i} - mean(referencevalues)) ./ std(referencevalues);
                    end
                end
                
            end
        end
        
        %if yvalues is not empty, but all values are nan, we should treat it as if it was empty (e.g. no autochange in colour)
        if ~isempty(yvalues)
            if iscell(yvalues) && ~any(~isnan(horzcat(yvalues{:})))
                yvalues = {};
            end
            if ~iscell(yvalues) && ~any(any(yvalues))
                yvalues = [];
            end
        end
        
        extraoptions(1:5) = {'keepfigure', 'color', colortracetouse, 'errorcolor', colorerrortouse};
        
        if ~transparent
            extraoptions(end+1) = {'noalpha'};
        end
        
        if displaytracehow == CONST_GUI_TRACE_HOW_MEAN
            if displayerrorwhat == CONST_GUI_ERROR_WHAT_SEM
                extraoptions(end+1) = {'sem'};
            elseif displayerrorwhat == CONST_GUI_ERROR_WHAT_STD
                extraoptions(end+1) = {'std'};
            elseif displayerrorwhat == CONST_GUI_ERROR_WHAT_NOTHING
                extraoptions(end+1) = {'noerror'};
            end
        elseif displaytracehow == CONST_GUI_TRACE_HOW_INDIVIDUAL
            extraoptions(end+1) = {'individual'};
        end
        if displayerrorhow == CONST_GUI_ERROR_HOW_AREA
            extraoptions(end+1) = {'errorarea'};
        elseif displayerrorhow == CONST_GUI_ERROR_HOW_LINES
            extraoptions(end+1) = {'errorlines'};
        elseif displayerrorhow == CONST_GUI_ERROR_HOW_BARS
            extraoptions(end+1) = {'errorbars'};
        end
        extraoptions(end+1) = {'style'};
        if alignwhat == CONST_GUI_ALIGN_WHAT_OXYGEN %((alignwhat == CONST_GUI_ALIGN_WHAT_SPEED || alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY) && numel(binnumbers)>1 && ~isnan(binnumbers(1))) || ...
            if displayerrorhow == CONST_GUI_ERROR_HOW_BARS
                extraoptions(end+1) = {'+'};
            else
                extraoptions(end+1) = {'-+'};
            end
            %CHANGEME
            %if numel(selectedregions) < numel(get(gui.regions,'String'))
                if strcmpi(colortrace, 'b')
                    xvalues = xvalues - 0.20; 
                elseif strcmpi(colortrace, 'g')
                    xvalues = xvalues - 0.10; 
                elseif strcmpi(colortrace, 'r')
                    xvalues = xvalues + 0.00; 
                elseif strcmpi(colortrace, 'c')
                    xvalues = xvalues + 0.10;
                elseif strcmpi(colortrace, 'm')
                    xvalues = xvalues + 0.20;
                elseif strcmpi(colortrace, 'y')
                    xvalues = xvalues + 0.30;
                elseif strcmpi(colortrace, 'k')
                    xvalues = xvalues + 0.40;
                end
            %end
        elseif (alignwhat == CONST_GUI_ALIGN_WHAT_SPEED || alignwhat == CONST_GUI_ALIGN_WHAT_VELOCITY) && numel(binnumbers)>1 && ~isnan(binnumbers(1))
            extraoptions(end+1) = {'+-'};
        else
            extraoptions(end+1) = {'-'};
        end
        
        if displaytracewhat == CONST_GUI_TRACE_WHAT_SPECTRALDENSITY
            if ~isempty(extracted) && isfield(extracted, 'objectids') && ~isempty(extracted(1).objectids) && ~isnan(extracted(1).objectids(1))
                xvalues = objects(extracted(1).objectids(1)).spectraldensityHz;
                %checking that all of what we're trying to average have the same Hz as xvalues
                whichnotthesame = [];
                for che = 1:numel(extracted) %checking extracted
                    uniqueoids = unique(extracted(che).objectids);
                    for cho = 1:numel(uniqueoids) %checking objectids
                        if numel(xvalues) ~= numel(objects(uniqueoids(cho)).spectraldensityHz) || ~all(xvalues == objects(uniqueoids(cho)).spectraldensityHz)
                            whichnotthesame = horzcat(objects(uniqueoids(cho)).filenames{:});
                            break
                        end
                    end
                    if ~isempty(whichnotthesame)
                        break
                    end
                end
                if ~isempty(whichnotthesame)
                    questdlg(sprintf('There is a clash between the x-values of the spectral densities extracted from movies %s and %s . This is most likely due to a difference in framerates.', horzcat(objects(extracted(1).objectids(1)).filenames{:}), whichnotthesame), 'Plotting', 'OK', 'OK');
                    checkfigure;
                    return
                end
                if numel(xvalues) ~= numel(yvalues{1})
                    xvalues = linspace(xvalues(1), xvalues(end), numel(yvalues{1}));
                end
            end
        end
        

        
        
        %NOW PLOTTING FINALLY
        if ~isempty(yvalues)
            if numel(extracted) == 1 && displaytracewhat == CONST_GUI_TRACE_WHAT_RATIO && alignwhat == CONST_GUI_ALIGN_WHAT_NOTHING %&& any(objects(extracted(1).objectids(end)).behaviour ~= CONST_BEHAVIOUR_NEURON_UNKNOWN)
                currenttracehandle = NaN;
                for behaviourindex = 1:6
                    switch behaviourindex
                        case CONST_BEHAVIOUR_NEURON_UNKNOWN
                            behaviourcolour = 'k';
                        case CONST_BEHAVIOUR_NEURON_STATIONARY
                            behaviourcolour = 'g';
                        case CONST_BEHAVIOUR_NEURON_FORWARDS
                            behaviourcolour = 'b';
                        case CONST_BEHAVIOUR_NEURON_REVERSAL
                            behaviourcolour = 'r';
                        case CONST_BEHAVIOUR_NEURON_INVALID || CONST_BEHAVIOUR_NEURON_BADFRAME
                            behaviourcolour = 'y';
                        case CONST_BEHAVIOUR_NEURON_SHORTINTERVAL
                            behaviourcolour = 'c';
                        otherwise
                            behaviourcolour = 'k';
                    end
                    currentwhere = objects(extracted(1).objectids(end)).behaviour == behaviourindex;
                    if iscell(yvalues) && numel(yvalues) == 1
                        yvalues = yvalues{1};
                    end
                    currentxvalues = xvalues(currentwhere);
                    currentyvalues = yvalues(currentwhere);
                    xjump = find(diff(currentxvalues)>1);
                    while ~isempty(xjump)
                        currentxvalues = [currentxvalues(1:xjump(i)) NaN currentxvalues(xjump(i)+1:end)];
                        currentyvalues = [currentyvalues(1:xjump(i)) NaN currentyvalues(xjump(i)+1:end)];
                        xjump = find(diff(currentxvalues)>1);
                    end
                    plot(currentxvalues, currentyvalues, 'color', behaviourcolour)
                    if ~ishandle(currenttracehandle)
                        currenttracehandle = findobj(gui.mainimage, 'Type', 'line', 'color', behaviourcolour);
                    end
                end
            else
                if iscell(yvalues)
                    %CHANGEMEFROM
                    %{
                    fullmatrix = NaN(numel(yvalues), numel(xvalues));
                    for fulli = 1:numel(yvalues)
                        fullmatrix(fulli, 1:numel(yvalues{fulli})) = yvalues{fulli};
                    end
                    wherehowmany = sum(~isnan(fullmatrix), 1);
                    wherebad = wherehowmany < 5;
                    for yi = 1:size(fullmatrix, 1)
                        fullmatrix(yi, wherebad) = NaN;
                    end
                    yvalues = fullmatrix;
                    overallaverage = NaN;
                    overallstd = NaN;
                    %}
                    %CHANGEMEUNTIL
                    overallaverage = mean(cellfun(@(y) (mean(y(~isnan(y)))), yvalues));
                    overallstd = std(cellfun(@(y) (mean(y(~isnan(y)))), yvalues));
                    
                    %CHANGEMEFROM
                    %{
                    before = NaN(1, numel(yvalues));
                    during = NaN(1, numel(yvalues));
                    after = NaN(1, numel(yvalues));
                    beforestart = 1;
                    beforeend = 580;
                    duringstart = 680;
                    duringend = 1180;
                    afterstart = 1280;
                    afterend = 1780;
                    for nowi=1:numel(yvalues)
                        before(nowi) = nanmean(yvalues{nowi}(beforestart:beforeend));
                        during(nowi) = nanmean(yvalues{nowi}(duringstart:duringend));
                        after(nowi) = nanmean(yvalues{nowi}(afterstart:min([afterend numel(yvalues{nowi})])));
                    end
                    fprintf('%f +/- %f to %f +/- %f to %f +/- %f\n', nanmean(before), nanstd(before), nanmean(during), nanstd(during), nanmean(after), nanstd(after));
                    %}
                    %CHANGEMEUNTIL
                    
                else
                    overallaverage = mean(yvalues(~isnan(yvalues)));
                    overallstd = std(yvalues(~isnan(yvalues)));
                end
                if nargout == 0
                    %CHANGEME
                    fprintf('The average value over the currently plotted trace is %f +/- %f (std).\n', overallaverage, overallstd);
                    %fprintf('Mean:\n');
                    %fprintf('%f\t%f\t%f\t%f\n', nanmean(yvalues(:, 2)), nanmean(yvalues(:, 3)), nanmean(yvalues(:, 4)), nanmean(yvalues(:, 5)));
                    %fprintf('STD:\n');
                    %fprintf('%f\t%f\t%f\t%f\n', nanstd(yvalues(:, 2)), nanstd(yvalues(:, 3)), nanstd(yvalues(:, 4)), nanstd(yvalues(:, 5)));
                    %fprintf('N:\n');
                    %fprintf('%d\t%d\t%d\t%d\n', sum(~isnan(yvalues(:, 2))), sum(~isnan(yvalues(:, 3))), sum(~isnan(yvalues(:, 4))), sum(~isnan(yvalues(:, 5))));
                    %fprintf('SEM:\n');
                    %fprintf('%f\t%f\t%f\t%f\n\n', nanstd(yvalues(:, 2))/realsqrt(sum(~isnan(yvalues(:, 2)))), nanstd(yvalues(:, 3))/realsqrt(sum(~isnan(yvalues(:, 3)))), nanstd(yvalues(:, 4))/realsqrt(sum(~isnan(yvalues(:, 4)))), nanstd(yvalues(:, 5))/realsqrt(sum(~isnan(yvalues(:, 5)))));
                    %CHANGEME
                    zplot(yvalues, 'xvalues', xvalues, extraoptions{:});
                    %{
                    if iscell(yvalues)
                        fprintf('based on n=%d events from %d movies\n', numel(yvalues), numel(selectedfiles));
                    else
                        fprintf('based on n=%d events from %d movies\n', size(yvalues, 1), numel(selectedfiles));
                    end
                    %}
                end
                if get(gui.export, 'Value')
                    userfilename = inputdlg('Filename:', 'Enter the file name', 1, {''}, 'on');
                    userfilename = char(userfilename);
                    doexport = true;
                    if isempty(userfilename)
                        doexport = false;
                    end
                    if exist(userfilename, 'file') == 2
                        if ~strcmp(questdlg('File already exists. Overwrite it?','File already exists','Cancel','Overwrite','Overwrite'),'Overwrite')
                           doexport = false;
                        end
                    end
                    if doexport
                        if iscell(yvalues)
                            yexport = NaN(numel(yvalues), numel(xvalues));
                            for i=1:numel(yvalues)
                                yexport(i, 1:numel(yvalues{i})) = yvalues{i};
                            end
                        else
                            yexport = yvalues;
                        end
                        exportfile = fopen(userfilename, 'w');
                        for i=1:numel(xvalues)
                            fprintf(exportfile, '%d', xvalues(i));
                            for j=1:size(yexport, 1)
                                fprintf(exportfile, '\t%f', yexport(j, i));
                            end
                            fprintf(exportfile, '\n');
                        end
                        fclose(exportfile);
                    end
                end
                if nargout == 0
                    currenttracehandle = findobj(gui.mainimage, 'Type', 'line', 'color', colortrace);
                end
            end
            if nargout == 0
                if numel(currenttracehandle) > 1
                    %when we're plotting individual traces, they're all from the same region(s), so we only display one legend, but there would be multiple traces detected by findobj.
                    currenttracehandle = currenttracehandle(1); %This ensures that there's only one trace handle for that one legend name
                end
                legendtraces{end+1} = currenttracehandle; 
                if numel(selectedoxygens) == 1 %if it's a specific O2 environment, then we mention it
                    o2names = get(gui.oxygen, 'String');
                    o2name = o2names{get(gui.oxygen, 'Value')};
                    legendnames{end+1} = [currentlegendname ' ' o2name];
                else
                    legendnames{end+1} = currentlegendname;
                end

                if isdefaultcolor(colortrace) %if it was a default (pre-defined) colour, we step to the next one
                    colortrace = CONST_GUI_COLORDEFAULTS{mod(strfind(horzcat(CONST_GUI_COLORDEFAULTS{:}), colortrace), numel(CONST_GUI_COLORDEFAULTS))+1};
                    set(gui.displaycolortrace, 'String', colortrace);
                end
                if isdefaultcolor(colorerror) %if it was a default (pre-defined) colour, we step to the next one
                    colorerror = CONST_GUI_COLORDEFAULTS{mod(strfind(horzcat(CONST_GUI_COLORDEFAULTS{:}), colorerror), numel(CONST_GUI_COLORDEFAULTS))+1};
                    set(gui.displaycolorerror, 'String', colorerror);
                end
            end
        else
            if isempty(objects)
                errormessage = 'There is nothing to show because no data is loaded. Select the file(s) you want to look at on the left side, then click "read data".';
            elseif isempty(currentlegendname)
                errormessage = 'There is nothing to show because no region is selected. Select the region(s) you want to look at on the right side, then try again.';
            else
                errormessage = sprintf('There is nothing to show for the %s values of %s with the current settings.', extractedstring, displayedregionname);
            end
            questdlg(errormessage, 'Plotting', 'OK', 'OK');
        end
        
        if nargout > 0
            varargout{1} = xvalues;
            varargout{2} = yvalues;
        end
        
        checkfigure;
        
        set(gui.plotit, 'String', 'Add to plot');
        
    end

    function readdata (hobj, eventdata) %#ok<INUSD>
        
        try
        
            set(gui.readdata, 'String', 'Reading data...');
            drawnow;

            clearobjects;
            
            logdividewhich = [];
            logcorrectionfactor = [];

            for i=1:numel(selectedfiles)
                
                trackerdata = false;
                neurondata = false;
                logdata = false;

                if strcmpi(selectedfiles{i}(end-9:end), 'ztdata.mat');
                    trackerdata = true;
                elseif strcmpi(selectedfiles{i}(end-3:end), '.log');
                    logdata = true;
                end
                if ~trackerdata && ~neurondata && ~logdata %if we still don't know what kind of data is in the file, try to determine it %if strcmpi(selectedfiles{i}(end-15:end), 'analysisdata.mat');
                    %older versions of zentracker also saved data as "analysisdata" (same as with Neuron) so we have to look inside to determine which program it's from
                    lastwarn(''); %clearing lastwarn so that in the next step if lastwarn is set, we know it's a new warning
                    warning('off', 'MATLAB:load:variableNotFound');
                    tempload = load(fullfile(get(gui.folder, 'String'), selectedfiles{i}), 'objects', 'ratios');
                    warning('on', 'MATLAB:load:variableNotFound');
                    if isfield(tempload, 'objects') && ~isfield(tempload, 'ratios')
                        trackerdata = true;
                    elseif isfield(tempload, 'ratios') && ~isfield(tempload, 'objects')
                        neurondata = true;
                    end
                end
                if ~trackerdata && ~neurondata && ~logdata %if we still don't know what kind of data is in the file, ask the user if we should skip it or stop reading altogether
                    proceedornot = questdlg(sprintf('Warning: could not read data from file %s.', selectedfiles{i}),'Reading data','Skip this file and proceed','Cancel','Skip this file and proceed');
                    if strcmp(proceedornot, 'Cancel')
                        %stop reading in data, clear things already read, and reset stuff
                        unloadobjects;
                        set(gui.readdata, 'String', 'Read data');
                        return
                    else
                        continue; %try to read next file
                    end
                end

                if ~logdata
                    if trackerdata
                        toload = CONST_TOLOAD_TRACKERDATA;
                    elseif neurondata
                        toload = CONST_TOLOAD_NEURONDATA;
                    else
                        fprintf(2, 'Warning: Unable to determine what kind of data is being read. Assuming a format consistent with Neuron\n');
                        neurondata = true;
                        toload = CONST_TOLOAD_NEURONDATA;
                    end

                    lastwarn(''); %clearing lastwarn so that in the next step if lastwarn is set, we know it's a new warning
                    wasunabletoload = [];
                    warning('off', 'MATLAB:load:variableNotFound');
                    currentlyloaded = load(fullfile(get(gui.folder, 'String'), selectedfiles{i}), toload{:});
                    for j=1:numel(toload)
                        if ~isfield(currentlyloaded, toload{j})
                            wasunabletoload{end+1} = toload{j}; %#ok<AGROW>
                            eval(['currentlyloaded.' toload{j} ' = [];']);
                        end
                    end
                    warning('on', 'MATLAB:load:variableNotFound');
                    if ~isempty(lastwarn) || ~isempty(wasunabletoload)
                        fprintf('Warning: not all variables could be loaded from file %s.', selectedfiles{i});
                        for j=1:numel(wasunabletoload)
                            if j==1
                                fprintf(' The following variables were missing: %s', wasunabletoload{j});
                            else
                                fprintf(', %s', wasunabletoload{j})
                            end
                            if j==numel(wasunabletoload)
                                fprintf('.\n');
                            end
                        end
                    end
                end

                if neurondata
                    for j=1:size(currentlyloaded.ratios, 2)

                        %we actually want to make a new object even if all of the values are NaN, just so that if/when data from a subsequent movie is appended to it, the values will be displaced appropriately
                        %objects that turn out not to contain any useful values will be removed AFTER all of the movies are read (subsequent movies can append useful values to the currently apparently useless object)

                        addtoobject = NaN;
                        previousratiolength = 0;
                        previousfilenames = [];
                        if successivemovies
                            dashes = strfind(selectedfiles{i}, '-');
                            numberat = dashes(end)-1;
                            currentnumber = str2double(selectedfiles{i}(numberat));
                            if ~isnan(currentnumber) && currentnumber > 0
                                expectedpreviousfilename = selectedfiles{i};
                                expectedpreviousfilename(numberat) = num2str(currentnumber-1);
                                for k=1:objectsn
                                    if strcmp(objects(k).filenames{end}, expectedpreviousfilename)
                                        previousfilenames = objects(k).filenames; %we will be using previousfilename later even if addtoobject is not set! (e.g. when a region is present only in the second movie of a two movie split - then we want to note that it is tied to the first movie (in terms of speed, for example) to make sure we don't count things more than once)
                                        if ~(previousratiolength == 0 || numel(objects(k).ratios) == previousratiolength)
                                            fprintf(2, 'Warning: there is an inconsistency between how long regions from the previous movie have data for. This means that we do not know what frame the current (subsequent) movie should start from. Continuing by assuming that the duration of the first valid region is the current one...\n');
                                        else
                                            previousratiolength = numel(objects(k).ratios);
                                        end
                                        if strcmp(objects(k).regionname, char(currentlyloaded.rationames(j, :)))
                                            addtoobject = k;
                                            break;
                                        end
                                    end
                                    if ~isnan(addtoobject)
                                        break;
                                    end
                                end
                            end
                        end

                        currentnf = size(currentlyloaded.ratios, 1);

                        if isempty(currentlyloaded.behaviour)
                            currentbehaviour = ones(1, currentnf).*CONST_BEHAVIOUR_NEURON_UNKNOWN;
                        else
                            currentbehaviour = currentlyloaded.behaviour;
                            %rotating 1d behaviour matrix if it's along the wrong dimension
                            if size(currentbehaviour, 1) > size(currentbehaviour, 2)
                                currentbehaviour = currentbehaviour';
                            end
                        end

                        currentregionname = char(currentlyloaded.rationames(j, :));

                        if numel(currentlyloaded.framex) <= 1 || numel(currentlyloaded.framey) <= 1 || isempty(currentlyloaded.regionname) || numel(currentlyloaded.frametime) <= 1 || ~any(~isnan(currentlyloaded.frametime))
                            currentabsx = NaN(1, currentnf);
                            currentabsy = NaN(1, currentnf);
                            timedelayestimate = NaN;
                        else
                            currentregionx = NaN(1, currentnf);
                            currentregiony = NaN(1, currentnf);
                            for frameindex=1:size(currentlyloaded.regionname, 1) %frame
                                for idindex=1:size(currentlyloaded.regionname, 2) %region id within the frame
                                    if strcmp(char(currentlyloaded.regionname(frameindex, idindex, :)), currentregionname)
                                        currentregionx(frameindex) = currentlyloaded.rightregionx(frameindex, idindex);
                                        currentregiony(frameindex) = currentlyloaded.rightregiony(frameindex, idindex);
                                        continue;
                                    end
                                end
                            end
                            currentregionx(currentregionx == 0) = NaN;
                            currentregiony(currentregiony == 0) = NaN;

                            currentabsx = currentlyloaded.framex + CONST_CONVERT_REGIONX_TO_ACTUALX*currentregionx + CONST_CONVERT_REGIONY_TO_ACTUALX*currentregiony;
                            currentabsy = currentlyloaded.framey + CONST_CONVERT_REGIONX_TO_ACTUALY*currentregionx + CONST_CONVERT_REGIONY_TO_ACTUALY*currentregiony;

                            if size(currentlyloaded.frametime, 1) > 1
                                currentlyloaded.frametime = currentlyloaded.frametime';
                            end
                            currentdeltatime = [NaN diff(currentlyloaded.frametime)];
                            currentdeltatime = currentdeltatime / 1000; %converting ms to s

                            timedelayestimate = nanmedian(currentdeltatime);
                        end

                        currentratios = currentlyloaded.ratios(:, j)';

                        if isempty(currentlyloaded.oxygen)
                            currentoxygen = ones(1, numel(currentratios)) * CONST_OXYGEN_UNKNOWN;
                        else
                            currentoxygen = currentlyloaded.oxygen;
                        end 

                        if ~isnan(addtoobject)
                            currentratios = [objects(addtoobject).ratios currentratios]; %#ok<AGROW>
                            currentbehaviour = [objects(addtoobject).behaviour currentbehaviour]; %#ok<AGROW>
                            currentabsx = [objects(addtoobject).absx currentabsx]; %#ok<AGROW>
                            currentabsy = [objects(addtoobject).absy currentabsy]; %#ok<AGROW>
                            currentoxygen = [objects(addtoobject).oxygen currentoxygen]; %#ok<AGROW>
                            if isnan(timedelayestimate)
                                timedelayestimate = objects(addtoobject).deltatime;
                            end
                        else
                            objectsn = objectsn + 1;
                            addtoobject = objectsn;
                            currentratios = [NaN(1, previousratiolength) currentratios]; %#ok<AGROW>
                            currentbehaviour = [NaN(1, previousratiolength) currentbehaviour]; %#ok<AGROW>
                            currentabsx = [NaN(1, previousratiolength) currentabsx]; %#ok<AGROW>
                            currentabsy = [NaN(1, previousratiolength) currentabsy]; %#ok<AGROW>
                            currentoxygen = [ones(1, previousratiolength)* CONST_OXYGEN_UNKNOWN currentoxygen]; %#ok<AGROW>
                        end

                        objects(addtoobject).ratios = currentratios;
                        objects(addtoobject).behaviour = currentbehaviour;
                        objects(addtoobject).absx = currentabsx;
                        objects(addtoobject).absy = currentabsy;
                        objects(addtoobject).deltatime = timedelayestimate;
                        objects(addtoobject).filenames = [previousfilenames selectedfiles(i)];
                        objects(addtoobject).oxygen = currentoxygen;
                        objects(addtoobject).regionname = currentregionname;

                    end
                    
                elseif logdata
                    
                    if isempty(logdividewhich)
                        if strcmp(questdlg('Divide which channel by which channel when calculating ratios?','Calculating ratios from log analyser data','LEFT / RIGHT','RIGHT / LEFT','LEFT / RIGHT'),'LEFT / RIGHT')
                            logdividewhich = CONST_LOG_LEFTBYRIGHT;
                        else
                            logdividewhich = CONST_LOG_RIGHTBYLEFT;
                        end
                    end
                    
                    while isempty(logcorrectionfactor)
                        logcorrectionfactors = inputdlg('Correction factor:', 'Specify the correction factor');
                        logcorrectionfactor = str2double(char(logcorrectionfactors));
                        if isnan(logcorrectionfactor)
                            logcorrectionfactor = [];
                        end
                    end
                            
                    logfile = fopen(fullfile(get(gui.folder, 'String'), selectedfiles{i}), 'r');
                    objectsn = objectsn + 1;
                    currentframe = 0;
                    timevalues = [];
                    while true
                        currentframe = currentframe + 1;
                        currentline = fgets(logfile);
                        if ~ischar(currentline) && currentline == -1
                            break
                        end
                        A = sscanf(currentline, '%d %f %f %f %f  %f %f   %f %f  %f %f');
                        timevalues(end+1) = A(1); %#ok<AGROW>
                        if logdividewhich == CONST_LOG_LEFTBYRIGHT
                            objects(objectsn).ratios(currentframe) = (A(7)-A(2))/(A(11)-A(3)) - logcorrectionfactor;
                        elseif logdividewhich == CONST_LOG_RIGHTBYLEFT
                            objects(objectsn).ratios(currentframe) = (A(11)-A(3))/(A(7)-A(2)) - logcorrectionfactor;
                        end
                        objects(objectsn).behaviour(currentframe) = CONST_BEHAVIOUR_NEURON_UNKNOWN;
                        objects(objectsn).absx(currentframe) = A(4);
                        objects(objectsn).absy(currentframe) = A(5);
                        objects(objectsn).filenames = selectedfiles(i);
                        objects(objectsn).oxygen(currentframe) = CONST_OXYGEN_UNKNOWN;
                        objects(objectsn).regionname = 'logfile';
                    end
                    objects(objectsn).deltatime = nanmedian(diff(timevalues));

                elseif trackerdata

                    currentobjects = currentlyloaded.objects;
                    
                    %little fix for aligning mistimed movies
                    if ~isempty(strfind(selectedfiles{i}, '100frextraatbeginning'))
                        for j=1:numel(currentobjects)
                            currentobjects(j).frame = currentobjects(j).frame - 100;
                            currentobjects(j).time = currentobjects(j).time - 100/currentlyloaded.framerate;
                            currentobjects(j).behaviour(currentobjects(j).frame <= 0) = CONST_BEHAVIOUR_TRACKER_INVALID;
                        end
                        currentlyloaded.lastframe = currentlyloaded.lastframe-100;
                    end
                    
                    objects(end+1).ratios = NaN(1, currentlyloaded.lastframe); %#ok<AGROW>
                    objects(end).direction = NaN(1, currentlyloaded.lastframe);
                    objects(end).behaviour = ones(1, currentlyloaded.lastframe) * CONST_BEHAVIOUR_NEURON_UNKNOWN; %Since this is an average of all objects in the movie, "behaviour" is not an appropriate measurement, so we set it to unknown                    
                    objects(end).oxygen = ones(1, currentlyloaded.lastframe) * CONST_OXYGEN_UNKNOWN;

                    objects(end).speed = zeros(1, currentlyloaded.lastframe);
                    objects(end).velocity = zeros(1, currentlyloaded.lastframe);
                    objects(end).reversal = zeros(1, currentlyloaded.lastframe);
                    objects(end).revinit = zeros(1, currentlyloaded.lastframe);
                    objects(end).revdur = zeros(1, currentlyloaded.lastframe);
                    objects(end).omegas = zeros(1, currentlyloaded.lastframe);

                    objects(end).speedn = zeros(1, currentlyloaded.lastframe);
                    objects(end).velocityn = zeros(1, currentlyloaded.lastframe);
                    objects(end).reversaln = zeros(1, currentlyloaded.lastframe);
                    objects(end).revinitn = zeros(1, currentlyloaded.lastframe);
                    objects(end).revdurn = zeros(1, currentlyloaded.lastframe);
                    objects(end).omegasn = zeros(1, currentlyloaded.lastframe);
                    
                    
                    %extracting spectral density if orientation measure is available
                    mindurationforor = 20;
                    smalleststep = 0.05;
                    fbins = 0:smalleststep:currentlyloaded.framerate/2-smalleststep;
                    if isfield(currentobjects, 'orientation')
                        stretches = cell(0);
                        for ori=1:numel(currentobjects)
                            wheregood = currentobjects(ori).behaviour ~= CONST_BEHAVIOUR_TRACKER_INVALID & ~isnan(currentobjects(ori).orientation);
                            startindices = strfind(wheregood, [false true]);
                            endindices = strfind(wheregood, [true false]);
                            if currentobjects(ori).behaviour(1) ~= CONST_BEHAVIOUR_TRACKER_INVALID && ~isnan(currentobjects(ori).orientation(1))
                                startindices = [1, startindices]; %#ok<AGROW>
                            end
                            if currentobjects(ori).behaviour(end) ~= CONST_BEHAVIOUR_TRACKER_INVALID && ~isnan(currentobjects(ori).orientation(end))
                                endindices = [endindices, currentobjects(ori).duration]; %#ok<AGROW>
                            end
                            durations = endindices - startindices + 1;
                            goodstretches = find(durations >= mindurationforor);
                            for j=1:numel(goodstretches)
                                stretches{end+1} = currentobjects(ori).orientation(startindices(goodstretches(j)):endindices(goodstretches(j))); %#ok<AGROW>
                            end
                        end

                        powers = zeros(1, numel(fbins));
                        powersn = zeros(1, numel(fbins));

                        for ori=1:numel(stretches)
                            orchanges{ori} = diff(stretches{ori}); %#ok<AGROW>
                            wheremorethan90 = orchanges{ori}>90;
                            wherelessthanm90 = orchanges{ori}<-90;
                            orchanges{ori}(wheremorethan90) = 180-orchanges{ori}(wheremorethan90); %#ok<AGROW>
                            orchanges{ori}(wherelessthanm90) = 180+orchanges{ori}(wherelessthanm90); %#ok<AGROW>

                            x = orchanges{ori};% - mean(orchanges{ori});

                            [pxx, f] = periodogram(x, [], numel(x), currentlyloaded.framerate);

                            for j=1:numel(f)
                                intowhichbin = find(f(j)>=fbins, 1, 'last');
                                powers(intowhichbin) = powers(intowhichbin) + pxx(j);
                                powersn(intowhichbin) = powersn(intowhichbin) + 1;
                            end
                        end
                        
                        objects(end).spectraldensityP = powers ./ powersn;
                    else
                        objects(end).spectraldensityP = NaN(1, numel(fbins));
                    end
                    objects(end).spectraldensityHz = fbins;
                    
                        
                    for j=1:numel(currentobjects)
                        
                        if ~isfield(currentobjects(j), 'frame')
                            currentobjects(j).frame = round(currentobjects(j).time * currentlyloaded.framerate + 1);
                        end
                        
                        framedifference = max([1, round(speedover*currentlyloaded.framerate)]);
                        timedifference = framedifference / currentlyloaded.framerate; %converting back so that we preserve the potential small change introduced by the rounding to integer frame values in the previous step
                        
                        revstartframe = NaN;
                        for k=1:currentobjects(j).duration
                            if currentobjects(j).behaviour(k) ~= CONST_BEHAVIOUR_TRACKER_INVALID
                                if k>framedifference && ~any(currentobjects(j).behaviour(k-framedifference:k) == CONST_BEHAVIOUR_TRACKER_INVALID)
                                    objects(end).speed(currentobjects(j).frame(k)) = objects(end).speed(currentobjects(j).frame(k)) + hypot(currentobjects(j).x(k)-currentobjects(j).x(k-framedifference), currentobjects(j).y(k)-currentobjects(j).y(k-framedifference)) * currentlyloaded.scalingfactor / timedifference;
                                    objects(end).speedn(currentobjects(j).frame(k)) = objects(end).speedn(currentobjects(j).frame(k)) + 1;
                                end
                                if currentobjects(j).behaviour(k) == CONST_BEHAVIOUR_TRACKER_REVERSAL
                                    objects(end).reversal(currentobjects(j).frame(k)) = objects(end).reversal(currentobjects(j).frame(k)) + 1;
                                    objects(end).reversaln(currentobjects(j).frame(k)) = objects(end).reversaln(currentobjects(j).frame(k)) + 1;
                                    objects(end).omegas(currentobjects(j).frame(k)) = objects(end).omegas(currentobjects(j).frame(k)) + 0;
                                    objects(end).omegasn(currentobjects(j).frame(k)) = objects(end).omegasn(currentobjects(j).frame(k)) + 1;
                                    if k-framedifference >= 1
                                        objects(end).velocity(currentobjects(j).frame(k)) = objects(end).velocity(currentobjects(j).frame(k)) - hypot(currentobjects(j).x(k)-currentobjects(j).x(k-framedifference), currentobjects(j).y(k)-currentobjects(j).y(k-framedifference)) * currentlyloaded.scalingfactor / timedifference;
                                        objects(end).velocityn(currentobjects(j).frame(k)) = objects(end).velocityn(currentobjects(j).frame(k)) + 1;
                                    end
                                    if k > 1 && currentobjects(j).behaviour(k-1) == CONST_BEHAVIOUR_TRACKER_FORWARDS && isnan(revstartframe) %if not already reversing, and was moving forwards in the previous frame, then there was an opportunity to reverse, which the worm took here
                                        revstartframe = currentobjects(j).frame(k);
                                    end
                                elseif currentobjects(j).behaviour(k) == CONST_BEHAVIOUR_TRACKER_FORWARDS
                                    objects(end).reversal(currentobjects(j).frame(k)) = objects(end).reversal(currentobjects(j).frame(k)) + 0;
                                    objects(end).reversaln(currentobjects(j).frame(k)) = objects(end).reversaln(currentobjects(j).frame(k)) + 1;
                                    objects(end).omegas(currentobjects(j).frame(k)) = objects(end).omegas(currentobjects(j).frame(k)) + 0;
                                    objects(end).omegasn(currentobjects(j).frame(k)) = objects(end).omegasn(currentobjects(j).frame(k)) + 1;
                                    if k-framedifference >= 1
                                        objects(end).velocity(currentobjects(j).frame(k)) = objects(end).velocity(currentobjects(j).frame(k)) + hypot(currentobjects(j).x(k)-currentobjects(j).x(k-framedifference), currentobjects(j).y(k)-currentobjects(j).y(k-framedifference)) * currentlyloaded.scalingfactor / timedifference;
                                        objects(end).velocityn(currentobjects(j).frame(k)) = objects(end).velocityn(currentobjects(j).frame(k)) + 1;
                                    end
                                    if k > 1 && currentobjects(j).behaviour(k-1) == CONST_BEHAVIOUR_TRACKER_FORWARDS %after having moved forwards in the previous frame, there was now an opportunity to reverse, which the worm missed here
                                        objects(end).revinit(currentobjects(j).frame(k)) = objects(end).revinit(currentobjects(j).frame(k)) + 0;
                                        objects(end).revinitn(currentobjects(j).frame(k)) = objects(end).revinitn(currentobjects(j).frame(k)) + 1;
                                    end
                                    if ~isnan(revstartframe)
                                        if (currentobjects(j).frame(k)-revstartframe+1)/currentlyloaded.framerate >= 1 %if the reversal lasted at least a second (i.e. it's not just random fluctuation),
                                            objects(end).revinit(revstartframe) = objects(end).revinit(revstartframe) + 1;
                                            objects(end).revinitn(revstartframe) = objects(end).revinitn(revstartframe) + 1;
                                            objects(end).revdur(revstartframe) = objects(end).revdur(revstartframe) + (currentobjects(j).frame(k)-revstartframe+1)/currentlyloaded.framerate;
                                            objects(end).revdurn(revstartframe) = objects(end).revdurn(revstartframe) + 1;
                                        end
                                        revstartframe = NaN;
                                    end
                                elseif currentobjects(j).behaviour(k) == CONST_BEHAVIOUR_TRACKER_OMEGA
                                    objects(end).reversal(currentobjects(j).frame(k)) = objects(end).reversal(currentobjects(j).frame(k)) + 0;
                                    objects(end).reversaln(currentobjects(j).frame(k)) = objects(end).reversaln(currentobjects(j).frame(k)) + 1;
                                    objects(end).omegas(currentobjects(j).frame(k)) = objects(end).omegas(currentobjects(j).frame(k)) + 1;
                                    objects(end).omegasn(currentobjects(j).frame(k)) = objects(end).omegasn(currentobjects(j).frame(k)) + 1;
                                    if ~isnan(revstartframe) %a reversal may be terminated by an omega
                                        if (currentobjects(j).frame(k)-revstartframe+1)/currentlyloaded.framerate >= 1 %if the reversal lasted at least a second (i.e. it's not just random fluctuation),
                                            objects(end).revinit(revstartframe) = objects(end).revinit(revstartframe) + 1;
                                            objects(end).revinitn(revstartframe) = objects(end).revinitn(revstartframe) + 1;
                                            objects(end).revdur(revstartframe) = objects(end).revdur(revstartframe) + (currentobjects(j).frame(k)-revstartframe+1)/currentlyloaded.framerate;
                                            objects(end).revdurn(revstartframe) = objects(end).revdurn(revstartframe) + 1;
                                        end
                                        revstartframe = NaN;
                                    end
                                end
                            else %invalid frame
                                revstartframe = NaN; %we don't know where the reversal ended because the behaviour became invalid
                            end
                        end
                    end
                    
                    objects(end).speed = objects(end).speed ./ objects(end).speedn;
                    objects(end).velocity = objects(end).velocity ./ objects(end).velocityn;
                    objects(end).reversal = objects(end).reversal ./ objects(end).reversaln;
                    objects(end).revinit = objects(end).revinit ./ objects(end).revinitn;
                    objects(end).revdur = objects(end).revdur ./ objects(end).revdurn;
                    objects(end).omegas = objects(end).omegas ./ objects(end).omegasn;
                    
                    objects(end).regionname = CONST_TRACKER_REGIONNAME;
                    objects(end).filenames = selectedfiles(i);
                    objects(end).deltatime = 1/currentlyloaded.framerate;
                    
                    if isfield(currentlyloaded, 'flashindices')
                        objects(end).flashindices = currentlyloaded.flashindices;
                    end
                    if isfield(currentlyloaded, 'framerate')
                        objects(end).framerate = currentlyloaded.framerate;
                    end
                    
                end
            end

            %now removing useless objects
            goodobjects = true(1, numel(objects));
            for i=1:numel(objects)
                anyratios = true;
                anyspeed = true;
                anybehaviour = true;
                if isempty(objects(i).ratios) || ~any(~isnan(objects(i).ratios))
                    anyratios = false;
                end
                if isempty(objects(i).absx) || ~any(~isnan(objects(i).absx)) || isempty(objects(i).absy) || ~any(~isnan(objects(i).absy))
                    if ~isfield(objects(i), 'speed') || isempty(objects(i).speed) || sum(isnan(objects(i).speed)) == numel(objects(i).speed)
                        anyspeed = false;
                    end
                end
                if isempty(objects(i).behaviour) || ~any(~isnan(objects(i).behaviour) & objects(i).behaviour ~= CONST_BEHAVIOUR_NEURON_UNKNOWN)
                    if ~isfield(objects(i), 'reversal') || isempty(objects(i).reversal) || sum(isnan(objects(i).reversal)) == numel(objects(i).reversal)
                        anybehaviour = false;
                    end
                end
                if ~anyratios && ~anyspeed && ~anybehaviour
                    goodobjects(i) = false;
                end
            end
            objects = objects(goodobjects);
            
            %adding a flashindices field to all objects
            for i=1:numel(objects)
                if ~isfield(objects(i), 'flashindices')
                    objects(i).flashindices = [];
                end
                if ~isfield(objects(i), 'framerate')
                    objects(i).framerate = NaN;
                end
            end

            set(gui.regions, 'String', sort(unique({objects.regionname})), 'Value', []);
            if numel(unique({objects.regionname})) == 1 %If there's only one behaviour to look at, we autoselect it by default since that's the only we they could want
                set(gui.regions, 'Value', 1);
            end
            selectregion; %updating which region is selected
            
            checkcanread;
        
        catch, err = lasterror; %#ok<CTCH,LERR> %catch err would be nicer, but that doesn't work on older versions of Matlab
            
            fprintf(2, '%s\n', err.message);
            try
                %We could reach this point without having i set (e.g. if the error occurred before we even entered the file reading loop), so we'll play it safe.
                %The extra message about which file failed isn't really necessary anyway.
                filethatfailed = selectedfiles{i}; 
                extraerrormessage = sprintf('The error occurred during the reading of the file %s', filethatfailed);
            catch %#ok<CTCH>
                extraerrormessage = '';
            end
            questdlg(['Warning: there was a problem with reading data.' extraerrormessage], 'Reading data', 'Cancel', 'Cancel');
            try %#ok<TRYNC>
                fclose(logfile);
            end
            unloaddata;
        end
        
    end

    %{
    function z1add(hobj, eventdata) %#ok<INUSD>
        if isnan(i1from) || isnan(i1until) || i1from > i1until
            questdlg('The "from" and "until" frames were inappropriately specified for i1', 'Invalid arguments', 'OK', 'OK');
            return
        end
        if ~readvariance
            questdlg('You must first the read variance when loading the data in order to use this function', 'Variance not available', 'OK', 'OK');
            return
        end 
        
        switch get(gui.displaytracewhat, 'Value')
            case CONST_GUI_TRACE_WHAT_SPEED
                currentmeans = {objects.speed};
                currentvars = {objects.speedvar};
                currentns = {objects.speedn};
            case CONST_GUI_TRACE_WHAT_VELOCITY
                currentmeans = {objects.velocity};
                currentvars = {objects.velocityvar};
                currentns = {objects.velocityn};
            case CONST_GUI_TRACE_WHAT_REVERSALS
                currentmeans = {objects.reversal};
                currentvars = {objects.reversalvar};
                currentns = {objects.reversaln};
            case CONST_GUI_TRACE_WHAT_REVINIT
                currentmeans = {objects.revinit};
                currentvars = {objects.revinitvar};
                currentns = {objects.revinitn};
            case CONST_GUI_TRACE_WHAT_REVDUR
                currentmeans = {objects.revdur};
                currentvars = {objects.revdurvar};
                currentns = {objects.revdurn};
            case CONST_GUI_TRACE_WHAT_OMEGAS
                currentmeans = {objects.omegas};
                currentvars = {objects.omegasvar};
                currentns = {objects.omegasn};
            otherwise
                questdlg('You must select a valid behaviour to store as z1', 'Invalid variable chosen for extraction', 'OK', 'OK');
                return
        end
        
        
        absframefrom = i1from+1;
        absframeuntil = i1until+1;
        
        alltogethermeans = [];
        alltogethervars = [];
        alltogetherns = [];
        for i=1:numel(currentmeans)
            intervalmeans = currentmeans{i}(absframefrom:absframeuntil);
            intervalvars = currentvars{i}(absframefrom:absframeuntil);
            intervalns = currentns{i}(absframefrom:absframeuntil);
            alltogethermeans(end+1:end+numel(intervalmeans)) = intervalmeans;
            alltogethervars(end+1:end+numel(intervalvars)) = intervalvars;
            alltogetherns(end+1:end+numel(intervalns)) = intervalns;
        end
        alltogethermeans(alltogetherns == 0) = [];
        alltogethervars(alltogetherns == 0) = [];
        alltogetherns(alltogetherns == 0) = [];
        
        z1mean = wmean(alltogethermeans, alltogetherns);
        z1var = sum((alltogetherns-1).*alltogethervars)/sum(alltogetherns-1); %pooled variance
        z1n = max(alltogetherns);
        
        if ~isnan(z1mean)
            questdlg('Data successfully added to z1', 'z1 set', 'OK', 'OK');
        end
    end


    function z2add(hobj, eventdata) %#ok<INUSD>
        if isnan(i2from) || isnan(i2until) || i2from > i2until
            questdlg('The "from" and "until" frames were inappropriately specified for i2', 'Invalid arguments', 'OK', 'OK');
            return
        end
        if ~readvariance
            questdlg('You must first the read variance when loading the data in order to use this function', 'Invalid arguments', 'OK', 'OK');
            return
        end 
        
        switch get(gui.displaytracewhat, 'Value')
            case CONST_GUI_TRACE_WHAT_SPEED
                currentmeans = {objects.speed};
                currentvars = {objects.speedvar};
                currentns = {objects.speedn};
            case CONST_GUI_TRACE_WHAT_VELOCITY
                currentmeans = {objects.velocity};
                currentvars = {objects.velocityvar};
                currentns = {objects.velocityn};
            case CONST_GUI_TRACE_WHAT_REVERSALS
                currentmeans = {objects.reversal};
                currentvars = {objects.reversalvar};
                currentns = {objects.reversaln};
            case CONST_GUI_TRACE_WHAT_REVINIT
                currentmeans = {objects.revinit};
                currentvars = {objects.revinitvar};
                currentns = {objects.revinitn};
            case CONST_GUI_TRACE_WHAT_REVDUR
                currentmeans = {objects.revdur};
                currentvars = {objects.revdurvar};
                currentns = {objects.revdurn};
            case CONST_GUI_TRACE_WHAT_OMEGAS
                currentmeans = {objects.omegas};
                currentvars = {objects.omegasvar};
                currentns = {objects.omegasn};
            otherwise
                questdlg('You must select a valid behaviour to store as z2', 'Invalid variable chosen for extraction', 'OK', 'OK');
                return
        end
        
        
        absframefrom = i2from+1;
        absframeuntil = i2until+1;
        
        alltogethermeans = [];
        alltogethervars = [];
        alltogetherns = [];
        for i=1:numel(currentmeans)
            intervalmeans = currentmeans{i}(absframefrom:absframeuntil);
            intervalvars = currentvars{i}(absframefrom:absframeuntil);
            intervalns = currentns{i}(absframefrom:absframeuntil);
            alltogethermeans(end+1:end+numel(intervalmeans)) = intervalmeans;
            alltogethervars(end+1:end+numel(intervalvars)) = intervalvars;
            alltogetherns(end+1:end+numel(intervalns)) = intervalns;
        end
        alltogethermeans(alltogetherns == 0) = [];
        alltogethervars(alltogetherns == 0) = [];
        alltogetherns(alltogetherns == 0) = [];
        
        z2mean = wmean(alltogethermeans, alltogetherns);
        z2var = sum((alltogetherns-1).*alltogethervars)/sum(alltogetherns-1); %pooled variance
        z2n = max(alltogetherns);
        
        if ~isnan(z2mean)
            questdlg('Data successfully added to z2', 'z2 set', 'OK', 'OK');
        end
    end
    %}

    function u1add (hobj, eventdata) %#ok<INUSD>
        if isnan(i1from) || isnan(i1until) || i1from > i1until
            questdlg('The "from" and "until" frames were inappropriately specified for i1', 'Invalid arguments', 'OK', 'OK');
            return
        end
        
        u1 = [];
        
        if displaytracewhat ~= CONST_GUI_TRACE_WHAT_RATIO
            for i=1:numel(selectedfiles)
                currentlyloaded = load(fullfile(get(gui.folder, 'String'), selectedfiles{i}), 'objects', 'scalingfactor');

                goodframes = cell(0);
                for j=1:numel(currentlyloaded.objects)

                    currentframes = currentlyloaded.objects(j).frame;
                    currentbehaviours = currentlyloaded.objects(j).behaviour;

                    currentbehaviours(currentframes < i1from | currentframes > i1until) = CONST_BEHAVIOUR_TRACKER_INVALID;

                    wheregoodlong = strfind(currentbehaviours ~= CONST_BEHAVIOUR_TRACKER_INVALID, true(1, uminframes));

                    currentgoodbehaviours = false(1, numel(currentframes));
                    for k=1:numel(wheregoodlong)
                        currentgoodbehaviours(wheregoodlong(k):wheregoodlong(k)+uminframes-1) = true;
                    end

                    goodframes{end+1} = currentframes(currentgoodbehaviours); %#ok<AGROW>
                end

                inwhichframe = mode(horzcat(goodframes{:}));

                for j=1:numel(currentlyloaded.objects)
                    if ~any(goodframes{j} == inwhichframe)
                        continue
                    end
                    middleframeindex = find(currentlyloaded.objects(j).frame == inwhichframe);
                    if ~isempty(middleframeindex)
                        firstframeindex = middleframeindex;
                        for k=middleframeindex:-1:1
                            if currentlyloaded.objects(j).behaviour(k) ~= CONST_BEHAVIOUR_TRACKER_INVALID && currentlyloaded.objects(j).frame(k) >= i1from
                                firstframeindex = k;
                            else
                                break
                            end
                        end
                        lastframeindex = middleframeindex;
                        for k=middleframeindex:numel(currentlyloaded.objects(j).frame)
                            if currentlyloaded.objects(j).behaviour(k) ~= CONST_BEHAVIOUR_TRACKER_INVALID && currentlyloaded.objects(j).frame(k) <= i1until
                                lastframeindex = k;
                            else
                                break
                            end
                        end
                        if ~isnan(firstframeindex) && ~isnan(lastframeindex)
                            if displaytracewhat == CONST_GUI_TRACE_WHAT_SPEED
                                u1(end+1) = nanmean(currentlyloaded.objects(j).speed(firstframeindex:lastframeindex))*currentlyloaded.scalingfactor; %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVERSALS
                                u1(end+1) = nanmean(currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_REVERSAL); %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_OMEGAS
                                u1(end+1) = nanmean(currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVINIT
                                u1(end+1) = nanmean(currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_REVERSAL | currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                            end
                        end
                    end
                end
            end
        else %ratios
            
            goodframes = cell(0);
            
            for i=1:numel(objects)
                
                if ~ismember(objects(i).regionname, selectedregions) %don't look at it if it's not a region we're interested in (region must be one of those selected by the user)
                    goodframes{end+1} = []; %#ok<AGROW>
                    continue
                end
                
                currentratios = objects(i).ratios;
                currentbehaviours = objects(i).behaviour;
                currentbehaviours([1:i1from-1, i1until+1:end]) = CONST_BEHAVIOUR_NEURON_INVALID;
                currentbehaviours(isnan(currentratios)) = CONST_BEHAVIOUR_NEURON_INVALID;
                wheregoodlong = strfind(currentbehaviours ~= CONST_BEHAVIOUR_NEURON_INVALID, true(1, uminframes));
                currentgoodbehaviours = false(1, numel(currentratios));
                for k=1:numel(wheregoodlong)
                    currentgoodbehaviours(wheregoodlong(k):wheregoodlong(k)+uminframes-1) = true;
                end
                goodframes{end+1} = find(currentgoodbehaviours); %#ok<AGROW>
            end
            inwhichframe = mode(horzcat(goodframes{:}));


            for i=1:numel(objects)
                if ~any(goodframes{i} == inwhichframe)
                    continue
                end
                currentratios = objects(i).ratios;
                if deltaroverr
                    currentratios = converttodeltar(currentratios);
                end
                middleframeindex = inwhichframe;
                if ~isempty(middleframeindex)
                    firstframeindex = middleframeindex;
                    for k=middleframeindex:-1:1
                        if objects(i).behaviour(k) ~= CONST_BEHAVIOUR_NEURON_INVALID && k >= i1from
                            firstframeindex = k;
                        else
                            break
                        end
                    end
                    lastframeindex = middleframeindex;
                    for k=middleframeindex:numel(objects(i).ratios)
                        if objects(i).behaviour(k) ~= CONST_BEHAVIOUR_TRACKER_INVALID && k <= i1until
                            lastframeindex = k;
                        else
                            break
                        end
                    end
                    if ~isnan(firstframeindex) && ~isnan(lastframeindex)
                        u1(end+1) = nanmean(currentratios(firstframeindex:lastframeindex)); %#ok<AGROW>
                    end
                end
            end
        end
        
        if ~isempty(u1) && ~isnan(u1(1))
            questdlg(sprintf('Data successfully stored as u1.\nu1 currently consists of %d datapoints.\nu2 currently consists of %d datapoints.', numel(u1), numel(u2)), 'u1 set', 'OK', 'OK');
        end
    end

    function u2add (hobj, eventdata) %#ok<INUSD>
        if isnan(i2from) || isnan(i2until) || i2from > i2until
            questdlg('The "from" and "until" frames were inappropriately specified for i2', 'Invalid arguments', 'OK', 'OK');
            return
        end
        
        u2 = [];
        
        if displaytracewhat ~= CONST_GUI_TRACE_WHAT_RATIO
            for i=1:numel(selectedfiles)
                currentlyloaded = load(fullfile(get(gui.folder, 'String'), selectedfiles{i}), 'objects', 'scalingfactor');

                goodframes = cell(0);
                for j=1:numel(currentlyloaded.objects)

                    currentframes = currentlyloaded.objects(j).frame;
                    currentbehaviours = currentlyloaded.objects(j).behaviour;

                    currentbehaviours(currentframes < i2from | currentframes > i2until) = CONST_BEHAVIOUR_TRACKER_INVALID;

                    wheregoodlong = strfind(currentbehaviours ~= CONST_BEHAVIOUR_TRACKER_INVALID, true(1, uminframes));

                    currentgoodbehaviours = false(1, numel(currentframes));
                    for k=1:numel(wheregoodlong)
                        currentgoodbehaviours(wheregoodlong(k):wheregoodlong(k)+uminframes-1) = true;
                    end

                    goodframes{end+1} = currentframes(currentgoodbehaviours); %#ok<AGROW>
                end

                inwhichframe = mode(horzcat(goodframes{:}));

                for j=1:numel(currentlyloaded.objects)
                    if ~any(goodframes{j} == inwhichframe)
                        continue
                    end
                    middleframeindex = find(currentlyloaded.objects(j).frame == inwhichframe);
                    if ~isempty(middleframeindex)
                        firstframeindex = middleframeindex;
                        for k=middleframeindex:-1:1
                            if currentlyloaded.objects(j).behaviour(k) ~= CONST_BEHAVIOUR_TRACKER_INVALID && currentlyloaded.objects(j).frame(k) >= i2from
                                firstframeindex = k;
                            else
                                break
                            end
                        end
                        lastframeindex = middleframeindex;
                        for k=middleframeindex:numel(currentlyloaded.objects(j).frame)
                            if currentlyloaded.objects(j).behaviour(k) ~= CONST_BEHAVIOUR_TRACKER_INVALID && currentlyloaded.objects(j).frame(k) <= i2until
                                lastframeindex = k;
                            else
                                break
                            end
                        end
                        if ~isnan(firstframeindex) && ~isnan(lastframeindex)
                            if displaytracewhat == CONST_GUI_TRACE_WHAT_SPEED
                                u2(end+1) = nanmean(currentlyloaded.objects(j).speed(firstframeindex:lastframeindex))*currentlyloaded.scalingfactor; %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVERSALS
                                u2(end+1) = nanmean(currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_REVERSAL); %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_OMEGAS
                                u2(end+1) = nanmean(currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVINIT
                                u2(end+1) = nanmean(currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_REVERSAL | currentlyloaded.objects(j).behaviour(firstframeindex:lastframeindex) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                            end
                        end
                    end
                end
            end
            
        else %ratios
            
            goodframes = cell(0);
            
            for i=1:numel(objects)
                
                if ~ismember(objects(i).regionname, selectedregions) %don't look at it if it's not a region we're interested in (region must be one of those selected by the user)
                    goodframes{end+1} = []; %#ok<AGROW>
                    continue
                end
                
                currentratios = objects(i).ratios;
                currentbehaviours = objects(i).behaviour;
                currentbehaviours([1:i2from-1, i2until+1:end]) = CONST_BEHAVIOUR_NEURON_INVALID;
                currentbehaviours(isnan(currentratios)) = CONST_BEHAVIOUR_NEURON_INVALID;
                wheregoodlong = strfind(currentbehaviours ~= CONST_BEHAVIOUR_NEURON_INVALID, true(1, uminframes));
                currentgoodbehaviours = false(1, numel(currentratios));
                for k=1:numel(wheregoodlong)
                    currentgoodbehaviours(wheregoodlong(k):wheregoodlong(k)+uminframes-1) = true;
                end
                goodframes{end+1} = find(currentgoodbehaviours); %#ok<AGROW>
            end
            inwhichframe = mode(horzcat(goodframes{:}));


            for i=1:numel(objects)
                if ~any(goodframes{i} == inwhichframe)
                    continue
                end
                currentratios = objects(i).ratios;
                if deltaroverr
                    currentratios = converttodeltar(currentratios);
                end
                middleframeindex = inwhichframe;
                if ~isempty(middleframeindex)
                    firstframeindex = middleframeindex;
                    for k=middleframeindex:-1:1
                        if objects(i).behaviour(k) ~= CONST_BEHAVIOUR_NEURON_INVALID && k >= i2from
                            firstframeindex = k;
                        else
                            break
                        end
                    end
                    lastframeindex = middleframeindex;
                    for k=middleframeindex:numel(objects(i).ratios)
                        if objects(i).behaviour(k) ~= CONST_BEHAVIOUR_TRACKER_INVALID && k <= i2until
                            lastframeindex = k;
                        else
                            break
                        end
                    end
                    if ~isnan(firstframeindex) && ~isnan(lastframeindex)
                        u2(end+1) = nanmean(currentratios(firstframeindex:lastframeindex)); %#ok<AGROW>
                    end
                end
            end
        end
        
        if ~isempty(u2) && ~isnan(u2(1))
            questdlg(sprintf('Data successfully stored as u2.\nu1 currently consists of %d datapoints.\nu2 currently consists of %d datapoints.', numel(u1), numel(u2)), 'u2 set', 'OK', 'OK');
        end
    end

    function hlestimator = hlestimateunpaired(values1, values2)
        hldifferences = NaN(numel(values1), numel(values2));
        for i=1:numel(values1)
            for j=1:numel(values2)
                hldifferences(i, j) = values2(j) - values1(i);
            end
        end
        hlestimator = median(hldifferences(:));
    end

    function hlestimator = hlestimatepaired(values1, values2)
        directdifferences = values2 - values1;
        hldifferences = NaN(numel(directdifferences));
        for i=1:numel(directdifferences)
            for j=1:numel(directdifferences)
                hldifferences(i, j) = mean([directdifferences(i), directdifferences(j)]);
            end
        end
        hlestimator = median(hldifferences(:));
    end
    
    function rsum(hobj, eventdata) %#ok<INUSD>
        if ~checku
            return
        end
        fprintf('\n');
        fprintf('Interval 1 (%d-%d): n=%d around %f (median)\n', i1from, i1until, sum(~isnan(u1)), nanmedian(u1));
        fprintf('Interval 2 (%d-%d): n=%d around %f (median)\n', i2from, i2until, sum(~isnan(u2)), nanmedian(u2));
        [p, h, stats] = ranksum(u1, u2);
        HLestimator = hlestimateunpaired(u1, u2);
        if h == 1
            fprintf('Interval 2 tends to be ');
            if nanmedian(u2) > nanmedian(u1)
                fprintf('greater ');
            else
                fprintf('smaller ');
            end
            fprintf('than interval 1 (Hodges–Lehmann estimator: %f).\n', HLestimator);
            fprintf('Mann–Whitney U test significant with ');
        else
            fprintf('There does not appear to be a significant difference between the two intervals (HLdelta: %f).\n', HLestimator);
            fprintf('Mann–Whitney U test not significant with ');
        end
        fprintf('U = %.1f , ', stats.ranksum);
        fprintf('p = %g ', p);
        printsignificance(h, p);
        fprintf('\n');
    end

    function ks(hobj, eventdata) %#ok<INUSD>
        if ~checku
            return
        end
        fprintf('\n');
        fprintf('Interval 1 (%d-%d): n=%d around %f (median)\n', i1from, i1until, sum(~isnan(u1)), nanmedian(u1));
        fprintf('Interval 2 (%d-%d): n=%d around %f (median)\n', i2from, i2until, sum(~isnan(u2)), nanmedian(u2));
        [h, p, ks2stat] = kstest2(u1, u2);
        HLestimator = hlestimateunpaired(u1, u2);
        if h == 1
            fprintf('Interval 2 tends to be ');
            if nanmedian(u2) > nanmedian(u1)
                fprintf('greater ');
            else
                fprintf('smaller ');
            end
            fprintf('than interval 1 (Hodges–Lehmann estimator: %f).\n', HLestimator);
            fprintf('Kolmogorov-Smirnov test significant with ');
        else
            fprintf('There does not appear to be a significant difference between the two intervals (HLdelta: %f).\n', HLestimator);
            fprintf('Kolmogorov-Smirnov test not significant with ');
        end
        fprintf('D = %f , ', ks2stat);
        fprintf('p = %g ', p);
        printsignificance(h, p);
        fprintf('\n');
    end

    function unpairedt(hobj, eventdata) %#ok<INUSD>
        if ~checku
            return
        end
        fprintf('\n');
        fprintf('Interval 1 (%d-%d): n=%d around %f (mean)\n', i1from, i1until, sum(~isnan(u1)), nanmean(u1));
        fprintf('Interval 2 (%d-%d): n=%d around %f (mean)\n', i2from, i2until, sum(~isnan(u2)), nanmean(u2));
        if sum(~isnan(u1)) <= 3
            fprintf('There are insufficient number of valid datapoints to proceed with the test.\n');
            questdlg('u1 must contain at least 4 valid values in order to proceed with the test', 'Invalid arguments', 'OK', 'OK');
            return
        end
        if sum(~isnan(u2)) <= 3
            fprintf('There are insufficient number of valid datapoints to proceed with the test.\n');
            questdlg('u2 must contain at least 4 valid values in order to proceed with the test', 'Invalid arguments', 'OK', 'OK');
            return
        end
        lillieoldhigh = warning('query', 'stats:lillietest:OutOfRangePHigh');
        lillieoldlow = warning('query', 'stats:lillietest:OutOfRangePLow');
        warning('off', 'stats:lillietest:OutOfRangePHigh');
        warning('off', 'stats:lillietest:OutOfRangePLow');
        lastwarn('');
        [h1, p1] = lillietest(u1);
        [lilliemessage, lillieid1] = lastwarn; %#ok<ASGLU>
        lastwarn('');
        [h2, p2] = lillietest(u2);
        [lilliemessage, lillieid2] = lastwarn; %#ok<ASGLU>
        if h1 == 0
            fprintf('Interval 1 appears normal according to the Lilliefors test (p%s%g).\n', psign(lillieid1), p1);
        else
            fprintf('Interval 1 appears non-normal according to the Lilliefors test (p%s%g).\n', psign(lillieid1), p1);
        end
        if h2 == 0
            fprintf('Interval 2 appears normal according to the Lilliefors test (p%s%g).\n', psign(lillieid2), p2);
        else
            fprintf('Interval 2 appears non-normal according to the Lilliefors test (p%s%g).\n', psign(lillieid2), p2);
        end
        if h1 == 1 || h2 == 1
            if any(u1 <= 0) || any(u2 <= 0)
                if all(u1(~isnan(u1)) >= 0 & u1(~isnan(u1)) <= 1) && all(u2(~isnan(u2)) >= 0 & u2(~isnan(u2)) <= 1)
                    u1transformed = asintransform(u1, Inf);
                    u2transformed = asintransform(u2, Inf);
                    fprintf('The data appear to consist of proportions. Applying an arcsine transformation.\n');
                else
                    if ~any(u1 < 0) && ~any(u2 < 0)
                        translateby = 0.5; %convention
                    else
                        translateby = -min(min(u1(~isnan(u1))), min(u2(~isnan(u2)))) + 1;
                    end
                    fprintf('The data include nonpositive values. Applying a translation of +%f prior to the log-transformation.\n', translateby)
                    u1transformed = log(u1 + translateby);
                    u2transformed = log(u2 + translateby);
                end
            else
                u1transformed = log(u1);
                u2transformed = log(u2);
                fprintf('Applying a log-transformation.\n');
            end
            lastwarn('');
            [h1l, p1l] = lillietest(u1transformed);
            [lilliemessage, lillieid1] = lastwarn; %#ok<ASGLU>
            lastwarn('');
            [h2l, p2l] = lillietest(u2transformed);
            [lilliemessage, lillieid2] = lastwarn; %#ok<ASGLU>
            fprintf('After the transformation, interval 1 ');
            if h1l == h1
                fprintf('still ');
            else
                fprintf('now ');
            end
            if h1l == 0
                fprintf('appears normal according to the Lilliefors test (p%s%g).\n', psign(lillieid1), p1l);
            else
                fprintf('appears non-normal according to the Lilliefors test (p%s%g).\n', psign(lillieid1), p1l);
            end
            fprintf('After the transformation, interval 2 ');
            if h2l == h2
                fprintf('still ');
            else
                fprintf('now ');
            end
            if h2l == 0
                fprintf('appears normal according to the Lilliefors test (p%s%g).\n', psign(lillieid2), p2l);
            else
                fprintf('appears non-normal according to the Lilliefors test (p%s%g).\n', psign(lillieid2), p2l);
            end
            if h1l || h2l
                fprintf('Normality appears to be violated even after the transformation. A t-test would be invalid in this case. Try nonparametric tests.\n');
                return
            end
            [h, p] = ttest2(u1transformed, u2transformed, 'Vartype', 'unequal');
            fprintf('Using the transformed data for the t-test.\n');
        else
            [h, p] = ttest2(u1, u2, 'Vartype', 'unequal');
        end
        if h == 1
            fprintf('Interval 2 tends to be ');
            if nanmean(u2) > nanmean(u1)
                fprintf('greater ');
            else
                fprintf('smaller ');
            end
            fprintf('than interval 1.\n');
            fprintf('Two-tailed unpaired Welch''s t-test significant with ');
        else
            fprintf('There does not appear to be a significant difference between the two intervals.\n');
            fprintf('Two-tailed unpaired Welch''s t-test not significant with ');
        end
        fprintf('p = %g ', p);
        printsignificance(h, p);
        warning(lillieoldhigh);
        warning(lillieoldlow);
        fprintf('\n');
    end

    function printsignificance (h, p)
        if h == 0
            fprintf('(ns)\n');
        elseif p <= 0.0001
            fprintf('(****)\n');
        elseif p <= 0.001
            fprintf('(***)\n');
        elseif p <= 0.01
            fprintf('(**)\n');
        elseif p <= 0.05
            fprintf('(*)\n');
        end
    end

    function canproceed = checku
        if sum(~isnan(u1)) == 0
            questdlg('u1 does not contain valid values', 'Invalid arguments', 'OK', 'OK');
            canproceed = false;
        elseif sum(~isnan(u2)) == 0
            questdlg('u2 does not contain valid values', 'Invalid arguments', 'OK', 'OK');
            canproceed = false;
        else
            canproceed = true;
        end
    end

    function pstring = psign (potentialpwarning)
        if strcmp(potentialpwarning, 'stats:lillietest:OutOfRangePHigh')
            pstring = ('>');
        elseif strcmp(potentialpwarning, 'stats:lillietest:OutOfRangePLow')
            pstring = ('<');
        else
            pstring = ('=');
        end
    end

    function [s1, s2] = extractpaired
        s1 = [];
        s2 = [];
        
        if displaytracewhat ~= CONST_GUI_TRACE_WHAT_RATIO
            for i=1:numel(selectedfiles)
                currentlyloaded = load(fullfile(get(gui.folder, 'String'), selectedfiles{i}), 'objects', 'scalingfactor');
                for j=1:numel(currentlyloaded.objects)

                    if any(currentlyloaded.objects(j).frame >= i1from & currentlyloaded.objects(j).frame <= i1until) && any(currentlyloaded.objects(j).frame >= i2from & currentlyloaded.objects(j).frame <= i2until)
                        if any(currentlyloaded.objects(j).behaviour(find(currentlyloaded.objects(j).frame == i1until)+1:find(currentlyloaded.objects(j).frame == i2from)-1) == CONST_BEHAVIOUR_TRACKER_INVALID)
                            continue
                        end
                        workable1first = NaN;
                        workable1last = find(currentlyloaded.objects(j).frame == i1until);
                        workable2first = find(currentlyloaded.objects(j).frame == i2from);
                        workable2last = NaN;
                        for k=i1until:-1:i1from
                            currentframe = find(currentlyloaded.objects(j).frame == k);
                            if isempty(currentframe) || currentlyloaded.objects(j).behaviour(currentframe) == CONST_BEHAVIOUR_TRACKER_INVALID
                                break
                            else
                                workable1first = currentframe;
                            end
                        end
                        for k=i2from:+1:i2until
                            currentframe = find(currentlyloaded.objects(j).frame == k);
                            if isempty(currentframe) || currentlyloaded.objects(j).behaviour(currentframe) == CONST_BEHAVIOUR_TRACKER_INVALID
                                break
                            else
                                workable2last = currentframe;
                            end
                        end
                        if ~isnan(workable1first) && ~isnan(workable2last) && currentlyloaded.objects(j).frame(workable1last)-currentlyloaded.objects(j).frame(workable1first)+1 >= sminframes && currentlyloaded.objects(j).frame(workable2last)-currentlyloaded.objects(j).frame(workable2first)+1 >= sminframes
                            %fprintf('%d to %d\n', objects(i).frame(workable1first), objects(i).frame(workable2last));
                            if displaytracewhat == CONST_GUI_TRACE_WHAT_SPEED
                                s1(end+1) = nanmean(currentlyloaded.objects(j).speed(workable1first:workable1last))*currentlyloaded.scalingfactor; %#ok<AGROW>
                                s2(end+1) = nanmean(currentlyloaded.objects(j).speed(workable2first:workable2last))*currentlyloaded.scalingfactor; %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVERSALS
                                s1(end+1) = nanmean(currentlyloaded.objects(j).behaviour(workable1first:workable1last) == CONST_BEHAVIOUR_TRACKER_REVERSAL); %#ok<AGROW>
                                s2(end+1) = nanmean(currentlyloaded.objects(j).behaviour(workable2first:workable2last) == CONST_BEHAVIOUR_TRACKER_REVERSAL); %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_OMEGAS
                                s1(end+1) = nanmean(currentlyloaded.objects(j).behaviour(workable1first:workable1last) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                                s2(end+1) = nanmean(currentlyloaded.objects(j).behaviour(workable2first:workable2last) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                            elseif displaytracewhat == CONST_GUI_TRACE_WHAT_REVINIT
                                s1(end+1) = nanmean(currentlyloaded.objects(j).behaviour(workable1first:workable1last) == CONST_BEHAVIOUR_TRACKER_REVERSAL | currentlyloaded.objects(j).behaviour(workable1first:workable1last) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                                s2(end+1) = nanmean(currentlyloaded.objects(j).behaviour(workable2first:workable2last) == CONST_BEHAVIOUR_TRACKER_REVERSAL | currentlyloaded.objects(j).behaviour(workable2first:workable2last) == CONST_BEHAVIOUR_TRACKER_OMEGA); %#ok<AGROW>
                            end
                        end
                    end
                end
            end
        else %ratios
            
            for i=1:numel(objects)
                
                if ~ismember(objects(i).regionname, selectedregions) %don't look at it if it's not a region we're interested in (region must be one of those selected by the user)
                    continue
                end
                
                currentratios = objects(i).ratios;
                if deltaroverr
                    currentratios = converttodeltar(currentratios);
                end
                
                if numel(currentratios) >= i2from+sminframes-1
                    i1fromchecked = round(max(i1from, 1));
                    i1untilchecked = round(min(i1until, numel(currentratios)));
                    i2fromchecked = round(max(i2from, 1));
                    i2untilchecked = round(min(i2until, numel(currentratios)));
                    leftinterval = currentratios(i1fromchecked:i1untilchecked);
                    rightinterval = currentratios(i2fromchecked:i2untilchecked);
                    if sum(~isnan(leftinterval)) >= sminframes && sum(~isnan(rightinterval)) >= sminframes
                        s1(end+1) = nanmean(leftinterval); %#ok<AGROW>
                        s2(end+1) = nanmean(rightinterval); %#ok<AGROW>
                    end
                end
            end
            
        end
    end

    function ssign(hobj, eventdata) %#ok<INUSD>
        if isnan(i1from) || isnan(i1until) || i1from > i1until
            questdlg('The "from" and "until" frames were inappropriately specified for i1', 'Invalid arguments', 'OK', 'OK');
            return
        end
        if isnan(i2from) || isnan(i2until) || i2from > i2until
            questdlg('The "from" and "until" frames were inappropriately specified for i2', 'Invalid arguments', 'OK', 'OK');
            return
        end
        
        [s1, s2] = extractpaired;
        
        fprintf('\n');
        fprintf('Interval 1 (%d-%d): n=%d around %f (median)\n', i1from, i1until, sum(~isnan(s1)), nanmedian(s1));
        fprintf('Interval 2 (%d-%d): n=%d around %f (median)\n', i2from, i2until, sum(~isnan(s2)), nanmedian(s2));
        
        [p, h, stats] = signtest(s1, s2);
        HLestimator = hlestimatepaired(s1, s2);
        if h == 1
            fprintf('Interval 2 tends to be ');
            if median(s2) > median(s1)
                fprintf('greater ');
            else
                fprintf('smaller ');
            end
            fprintf('than interval 1 (Hodges–Lehmann estimator: %f).\n', HLestimator);
            fprintf('Sign test significant with ');
        else
            fprintf('There does not appear to be a significant difference between the two intervals (HLdelta: %f).\n', HLestimator);
            fprintf('Sign test not significant with ');
        end
        fprintf('W = %d , ', stats.sign);
        fprintf('p = %g ', p);
        printsignificance(h, p);
        fprintf('\n');
    end

    function pairedt(hobj, eventdata) %#ok<INUSD>
        if isnan(i1from) || isnan(i1until) || i1from > i1until
            questdlg('The "from" and "until" frames were inappropriately specified for i1', 'Invalid arguments', 'OK', 'OK');
            return
        end
        if isnan(i2from) || isnan(i2until) || i2from > i2until
            questdlg('The "from" and "until" frames were inappropriately specified for i2', 'Invalid arguments', 'OK', 'OK');
            return
        end
        
        [s1, s2] = extractpaired;
        
        fprintf('\n');
        fprintf('Interval 1 (%d-%d): n=%d around %f (mean)\n', i1from, i1until, sum(~isnan(s1)), nanmean(s1));
        fprintf('Interval 2 (%d-%d): n=%d around %f (mean)\n', i2from, i2until, sum(~isnan(s2)), nanmean(s2));
        if sum(~isnan(s2-s1)) <= 3
            fprintf('There are insufficient number of valid datapoints to proceed with the test.\n');
            questdlg('There must be at least 4 valid values in both interval 1 and 2 to proceed with the test', 'Invalid arguments', 'OK', 'OK');
            return
        end
        lillieoldhigh = warning('query', 'stats:lillietest:OutOfRangePHigh');
        lillieoldlow = warning('query', 'stats:lillietest:OutOfRangePLow');
        lastwarn('');
        warning('off', 'stats:lillietest:OutOfRangePHigh');
        warning('off', 'stats:lillietest:OutOfRangePLow');
        [h0, p0] = lillietest(s2-s1);
        [lilliemessage, lillieid] = lastwarn; %#ok<ASGLU>
        if h0 == 0
            fprintf('The differences between the two intervals appear to be normally distributed according to the Lilliefors test (p%s%g).\n', psign(lillieid), p0);
        else
            fprintf('The differences between the two intervals do not appear to be normally distributed according to the Lilliefors test (p%s%g).\n', psign(lillieid), p0);
        end
        if h0 == 1
            if any(s2-s1 <= 0)
                translateby = -min(s2-s1(~isnan(s2-s1))) + 1;
                fprintf('The differences include nonpositive values. Applying a translation of +%f prior to the log-transformation.\n', translateby)
            else
                translateby = 0;
            end
            lastwarn('');
            [h0l, p0l] = lillietest(log(s2-s1 + translateby));
            [lilliemessage, lillieid] = lastwarn; %#ok<ASGLU>
            if h0l == 0
                fprintf('After a log-transformation, the differences between the two intervals now appear to be normally distributed according to the Lilliefors test (p%s%g).\n', psign(lillieid), p0l);
            else
                fprintf('After a log-transformation, the differences between the two intervals still do not appear to be normally distributed according to the Lilliefors test (p%s%g).\n', psign(lillieid), p0l);
            end
            if h0l
                fprintf('Normality appears to be violated even after a log-transformation. A t-test would be invalid in this case. Try nonparametric tests.\n');
                return
            end
            [h, p] = ttest(log(s2-s1 + translateby));
            fprintf('Using log-transformed data for the t-test.\n');
        else
            [h, p] = ttest(s2-s1);
        end
        if h == 1
            fprintf('Interval 2 tends to be ');
            if nanmean(s2) > nanmean(s1)
                fprintf('greater ');
            else
                fprintf('smaller ');
            end
            fprintf('than interval 1.\n');
            fprintf('Two-tailed paired Student''s t-test significant with ');
        else
            fprintf('There does not appear to be a significant difference between the two intervals.\n');
            fprintf('Two-tailed paired Student''s t-test not significant with ');
        end
        
        fprintf('p = %g ', p);
        printsignificance(h, p);
        warning(lillieoldhigh);
        warning(lillieoldlow);
        fprintf('\n');
    end

    function asdelta = converttodeltar (inputvalues)
        if isnan(r0from)
            questdlg('Error: you must specify which frame to calculate R0 from', 'Calculating deltaR/R0', 'OK', 'OK');
            return;
        end
        if isnan(r0until)
            questdlg('Error: you must specify which frame to calculate R0 until', 'Calculating deltaR/R0', 'OK', 'OK');
            return;
        end
        r0fromchecked = round(max(r0from, 1));
        r0untilchecked = round(min(r0until, numel(inputvalues)));
        asdelta = (inputvalues./nanmedian(inputvalues(r0fromchecked:r0untilchecked)) - 1)*100;
    end

    %{
    function t1add(hobj, eventdata) %#ok<INUSD>
        if isnan(i1from) || isnan(i1until) || i1from > i1until
            questdlg('The "from" and "until" frames were inappropriately specified for i1', 'Invalid arguments', 'OK', 'OK');
            return
        end
        [currentx, currenty] = plotit;
        if iscell(currenty)
            t1 = NaN(1, numel(currenty));
            for i=1:numel(currenty)
                yvals = currenty{i}(find(currentx == i1from, 1, 'first'):find(currentx == i1until, 1, 'first'));
                t1(i) = mean(yvals(~isnan(yvals)));
            end
        else
            t1 = NaN(1, size(currenty, 1));
            for i=1:size(currenty, 1)
                 yvals = currenty(i, currentx(i, find(currentx == i1from, 1, 'first'):find(currentx == i1until, 1, 'first')));
                 t1(i) = mean(yvals(~isnan(yvals)));
            end
        end
        if ~isempty(t1)
            questdlg('Data successfully added to t1', 't1 set', 'OK', 'OK');
        end
    end

    function t2add(hobj, eventdata) %#ok<INUSD>
        if isnan(i2from) || isnan(i2until) || i2from > i2until
            questdlg('The "from" and "until" frames were inappropriately specified for i2', 'Invalid arguments', 'OK', 'OK');
            return
        end
        [currentx, currenty] = plotit;
        if iscell(currenty)
            t2 = NaN(1, numel(currenty));
            for i=1:numel(currenty)
                yvals = currenty{i}(find(currentx == i2from, 1, 'first'):find(currentx == i2until, 1, 'first'));
                t2(i) = mean(yvals(~isnan(yvals)));
            end
        else
            t2 = NaN(1, size(currenty, 1));
            for i=1:size(currenty, 1)
                 yvals = currenty(i, currentx(i, find(currentx == i2from, 1, 'first'):find(currentx == i2until, 1, 'first')));
                 t2(i) = mean(yvals(~isnan(yvals)));
            end
        end
        if ~isempty(t2)
            questdlg('Data successfully added to t2', 't2 set', 'OK', 'OK');
        end
    end

    function tzen(hobj, eventdata) %#ok<INUSD>
        
        s12 = realsqrt(z1var/z1n + z2var/z2n); %unbiased estimator of the variance of the two samples
        t = (z1mean - z2mean) / s12; %t-statistic
        df = (z1var/z1n + z2var/z2n)^2 / ((z1var/z1n)^2/(z1n-1) + (z2var/z2n)^2/(z2n-1)); %degrees of freedom
        p = 1-tcdf(abs(t),df);
        
        meandiff = z2mean - z1mean;
        fprintf('Interval 1 (%d-%d): %f +/- %f (SEM) with n=%d\n', i1from, i1until, z1mean, realsqrt(z1var)/realsqrt(z1n), z1n);
        fprintf('Interval 2 (%d-%d): %f +/- %f (SEM) with n=%d\n', i2from, i2until, z2mean, realsqrt(z2var)/realsqrt(z2n), z2n);
        fprintf('Interval 2 is %f ', abs(meandiff));
        if meandiff >= 0
            fprintf('greater than ');
        else
            fprintf('smaller than ');
        end
        fprintf('interval 1.\n');
        if p > 0.05
            fprintf('Two-sample two-tailed Welch''s t-test based on individual worms not significant with ');
        else
            fprintf('Two-sample two-tailed Welch''s t-test based on individual worms significant at ');
        end
        fprintf('p = %f ', p);
        if p <= 0.0001
            fprintf('(****)\n');
        elseif p <= 0.001
            fprintf('(***)\n');
        elseif p <= 0.01
            fprintf('(**)\n');
        elseif p <= 0.05
            fprintf('(*)\n');
        else
            fprintf('(ns)\n');
        end
        fprintf('Degrees of freedom: %f\n', df);
    end

    function tpaired(hobj, eventdata) %#ok<INUSD>
        [h, p] = ttest(t2-t1);
        meandiff = mean(t2-t1);
        fprintf('Interval 1 (%d-%d): %f +/- %f (SEM)\n', i1from, i1until, mean(t1), std(t1)/realsqrt(numel(t1)));
        fprintf('Interval 2 (%d-%d): %f +/- %f (SEM)\n', i2from, i2until, mean(t2), std(t2)/realsqrt(numel(t2)));
        fprintf('Interval 2 is %f ', abs(meandiff));
        if meandiff >= 0
            fprintf('greater than ');
        else
            fprintf('smaller than ');
        end
        fprintf('interval 1.\n');
        if h == 0
            fprintf('Paired two-tailed Student''s t-test based on individual movies not significant with ');
        else
            fprintf('Paired two-tailed Student''s t-test based on individual movies significant at ');
        end
        fprintf('p = %f ', p);
        printsignificance(h, p);
    end

    function tunpaired(hobj, eventdata) %#ok<INUSD>
        [h, p] = ttest2(t1, t2, [], [], 'unequal');
        meandiff = mean(t2)-mean(t1);
        fprintf('Interval 1 (%d-%d): %f +/- %f (SEM)\n', i1from, i1until, mean(t1), std(t1)/realsqrt(numel(t1)));
        fprintf('Interval 2 (%d-%d): %f +/- %f (SEM)\n', i2from, i2until, mean(t2), std(t2)/realsqrt(numel(t2)));
        fprintf('Interval 2 is %f ', abs(meandiff));
        if meandiff >= 0
            fprintf('greater than ');
        else
            fprintf('smaller than ');
        end
        fprintf('interval 1.\n');
        if h == 0
            fprintf('Two-sample two-tailed Welch''s t-test based on individual movies not significant with ');
        else
            fprintf('Two-sample two-tailed Welch''s t-test based on individual movies significant at ');
        end
        fprintf('p = %f ', p);
        printsignificance(h, p);
    end
    %}

    function unloaddata (hobj, eventdata) %#ok<INUSD>
        clearobjects;
        checkcanread;
    end
    
    function clearobjects (hobj, eventdata) %#ok<INUSD>
        objects = struct('ratios', {}, 'regionname', {}, 'filenames', {}, 'absx', {}, 'absy', {}, 'oxygen', {}, 'speed', {}, 'velocity', {}, 'direction', {}, 'reversal', {}, 'revinit', {}, 'revdur', {}, 'omegas', {});
        objectsn = 0;
        set(gui.regions, 'String', sort(unique({objects.regionname})), 'Value', []);
        selectregion;
    end

    function checkcanread
        if ~isempty(objects)
            set([gui.sortby, gui.refresh, gui.browse, gui.folder, gui.filefilter, gui.files, gui.readdata], 'Enable', 'off');
            set(gui.readdata, 'String', 'Read data', 'Position', [0.00 0.00 0.40 0.10]);
            set(gui.unloaddata, 'Enable', 'on', 'Position', [0.40 0.00 0.60 0.10]);
            %set(gui.readvariance, 'Visible', 'off');
            set(gui.successivemovies, 'Visible', 'off');
        else
            set([gui.sortby, gui.refresh, gui.browse, gui.folder, gui.filefilter, gui.files, gui.readdata], 'Enable', 'on');
            set(gui.readdata, 'String', 'Read data', 'Position', [0.00 0.03 0.60 0.07]);
            set(gui.unloaddata, 'Enable', 'off', 'Position', [0.60 0.03 0.40 0.07]);
            %set(gui.readvariance, 'Visible', 'on');
            set(gui.successivemovies, 'Visible', 'on');
        end
    end

    function checkspeedover (hobj, eventdata) %#ok<DEFNU,INUSD>
        if any(cellfun(@(comparename)any(strcmp(comparename, CONST_TRACKER_REGIONNAME)), get(gui.regions, 'String')))
            choice = questdlg('Warning: for the changes to the speed smoothing settings to take effect, the per movie averages of behavioural data need to be recalculated.','Speed smoothing','Proceed and recalculate the movie averages','Cancel','Proceed and recalculate the movie averages');
            if strcmp(choice, 'Proceed and recalculate the movie averages')
                newspeedover = str2double(get(gui.speedover, 'String'));
                if ~isnan(newspeedover)
                    speedover = newspeedover;
                end
                unloaddata;
                readdata;
            else
                set(gui.speedover, 'String', num2str(speedover));
            end
        end
    end

    function isit = isdefaultcolor (colortocheck)
        if numel(colortocheck) == 1 && ~isempty(strfind(horzcat(CONST_GUI_COLORDEFAULTS{:}), colortocheck))
            isit = true;
        else
            isit = false;
        end
    end

    function isit = wantedbehaviour (whichobject, whichframe, behaviourneeded)
        isit = (whichframe >= fromframe && whichframe <= untilframe) && (behaviourneeded == CONST_GUI_BEHAVIOUR_ANYTHING ...
        || behaviourneeded == CONST_GUI_BEHAVIOUR_UNKNOWN && objects(whichobject).behaviour(whichframe) == CONST_BEHAVIOUR_NEURON_UNKNOWN ...
        || behaviourneeded == CONST_GUI_BEHAVIOUR_FORWARDS && objects(whichobject).behaviour(whichframe) == CONST_BEHAVIOUR_NEURON_FORWARDS ...
        || behaviourneeded == CONST_GUI_BEHAVIOUR_REVERSAL && objects(whichobject).behaviour(whichframe) == CONST_BEHAVIOUR_NEURON_REVERSAL ...
        || behaviourneeded == CONST_GUI_BEHAVIOUR_STATIONARY && objects(whichobject).behaviour(whichframe) == CONST_BEHAVIOUR_NEURON_STATIONARY);
    end

    function asnumbers = string2matrix (inputstring, separatorchars)
        try
            separators = [];
            for i=1:numel(separatorchars)
                separators = union(separators, strfind(inputstring, separatorchars{i}));
            end
            separators = union(separators+1, 1); %adding a dummy separatorchar to the begining
            separators = union(separators, numel(inputstring)+2); %adding a dummy separatorchar to the end
            wheregood = true(1, 1+numel(inputstring)+1);
            wheregood(separators) = false;
            wherenumstarts = (strfind(wheregood, [false true])+1)-1;
            wherenumends = (strfind(wheregood, [true false]))-1;
            howmanynumbers = min([numel(wherenumstarts), numel(wherenumends)]);
            asnumbers = NaN(1, howmanynumbers);
            for i=1:howmanynumbers
                asnumbers(i) = str2double(inputstring(wherenumstarts(i):wherenumends(i)));
            end
        catch %#ok<CTCH>
            warning('stringtoRGB:invalidstring', 'Warning: could not convert colour string to RGB values.');
            asnumbers = [];
        end
        
    end
    
    %{
    function numberofelements = cellnumel (cellarray, arrayindex)
        if numel(cellarray) >= arrayindex
            numberofelements = numel(cellarray{arrayindex});
        else
            numberofelements = 0;
        end
    end
    %}

    function setvalue (hobj, eventdata, varargin) %#ok<INUSL>
        
        %parsing input arguments
        inputindex=1;
        while (inputindex<=numel(varargin))
            if strcmpi(varargin{inputindex}, 'min') || strcmpi(varargin{inputindex}, 'minvalue')
                minvalue = varargin{inputindex+1};
                if ischar(minvalue)
                    minvalue = eval(minvalue);
                end
                inputindex=inputindex+2;
            elseif strcmpi(varargin{inputindex}, 'max') || strcmpi(varargin{inputindex}, 'maxvalue')
                maxvalue = varargin{inputindex+1};
                if ischar(maxvalue)
                    maxvalue = eval(maxvalue);
                end
                inputindex=inputindex+2;
            elseif strcmpi(varargin{inputindex}, 'round') || strcmpi(varargin{inputindex}, 'rounding')
                rounding = varargin{inputindex+1};
                if ischar(rounding)
                    rounding = eval(rounding);
                end
                inputindex=inputindex+2;
            elseif strcmpi(varargin{inputindex}, 'default')
                default = varargin{inputindex+1};
                inputindex=inputindex+2;
            elseif strcmpi(varargin{inputindex}, 'set') || strcmpi(varargin{inputindex}, 'setglobal')
                setglobal = varargin{inputindex+1};
                inputindex=inputindex+2;
            elseif strcmpi(varargin{inputindex}, 'logical') || strcmpi(varargin{inputindex}, 'logic') == 1 || strcmpi(varargin{inputindex}, 'number')
                logic = true;
                inputindex=inputindex+1;
            elseif strcmpi(varargin{inputindex}, 'string')
                stringdata = true;
                inputindex=inputindex+1;
            elseif strcmpi(varargin{inputindex}, 'finally')
                finally = varargin{inputindex+1};
                inputindex=inputindex+2;
            else
                fprintf(2, 'Warning: function "setvalue" does not understand input argument %s. Skipping it...\n', varargin{inputindex});
                inputindex=inputindex+1;
            end
        end
        
        if exist('logic', 'var') ~= 1
            logic = false;
        end
        if exist('stringdata', 'var') ~= 1
            stringdata = false;
        end
        if exist('default', 'var') ~= 1
            if logic
                default = false;
            else
                default = '-';
            end
        end
        if exist('finally', 'var') ~= 1
            finally = [];
        end
        
        if ~logic && ~stringdata
            tempvalue = str2double(get(hobj, 'String'));
        elseif ~stringdata
            tempvalue = get(hobj, 'Value');
        elseif stringdata
            tempvalue = get(hobj, 'String');
        end
        
        if exist('rounding', 'var') == 1
            tempvalue = round(tempvalue * rounding)/rounding;
        end
        if exist('minvalue', 'var') == 1 && tempvalue < minvalue
            tempvalue = minvalue;
        end
        if exist('maxvalue', 'var') == 1 && tempvalue > maxvalue
            tempvalue = maxvalue;
        end
        if stringdata
            tempvalue = strtrim(tempvalue);
        end
        
        if ~logic && ~stringdata
            if ~isnan(tempvalue)
                set(hobj, 'String', num2str(tempvalue))
            else
                set(hobj, 'String', default);
            end
        elseif stringdata
            set(hobj, 'String', tempvalue);
        end
        
        if exist('setglobal', 'var') == 1
            if strcmpi(class(default), 'double') && isnan(tempvalue)
                eval([setglobal '= default;']);
            else
                eval([setglobal '= tempvalue;']);
            end
        end
        
        if ~isempty(finally)
            if iscell(finally)
                for i=1:numel(finally)
                    eval(finally{i});
                end
            else
                eval(finally);
            end
        end
        
    end

    function debuggingfunction (hobj, eventdata) %#ok<INUSD>
        
        %{
        i1from = 80;
        i1until = 580;
        u1add(hobj, eventdata);
        a1 = u1;
        
        i1from = 680;
        i1until = 1180;
        u1add(hobj, eventdata);
        a2 = u1;
        
        i1from = 1280;
        i1until = 1780;
        u1add(hobj, eventdata);
        a3 = u1;
        
        fprintf('%f\t%f\t%f\n', nanmean(a1), nanmean(a2), nanmean(a3));
        fprintf('%f\t%f\t%f\n', nanstd(a1)/realsqrt(numel(a1)), nanstd(a2)/realsqrt(numel(a1)), nanstd(a3)/realsqrt(numel(a1)));
        %}
        
        keyboard;
    end

end