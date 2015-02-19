%zplot 2.2
%
%plot average of traces with shaded area-style error indicators.
%
%takes a matrix or a (cell array of numerical arrays) as input data
%if the input is given as a matrix, then different rows (1st dimension) should be different individuals, and different columns (2nd dimension) should be different timepoints
%if the input is given as a cell array, then different cells should be different individuals, and the arrays within the cells should represent the timeseries. the timeseries will be assumed to start at the same point.

function [datamean, datan, datastd, datasem] = zplot (data, varargin)

    CONST_ERROR_WHAT_NOTHING = 0;
    CONST_ERROR_WHAT_SEM = 1;
    CONST_ERROR_WHAT_STD = 2;
    
    CONST_ERROR_HOW_AREA = 1;
    CONST_ERROR_HOW_LINES = 2;
    CONST_ERROR_HOW_BARS = 3;

    %parsing input arguments
    inputindex=1;
    while (inputindex<=numel(varargin))
        if strcmpi(varargin{inputindex}, 'colour') || strcmpi(varargin{inputindex}, 'color')
            colour = varargin{inputindex+1};
            inputindex=inputindex+2;
        elseif strcmpi(varargin{inputindex}, 'new') || strcmpi(varargin{inputindex}, 'new figure') || strcmpi(varargin{inputindex}, 'newfigure')
            newfigure = true;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'keep') || strcmpi(varargin{inputindex}, 'keep figure') || strcmpi(varargin{inputindex}, 'keepfigure')
            newfigure = false;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'noerror') || strcmpi(varargin{inputindex}, 'nosem') || strcmpi(varargin{inputindex}, 'nostd')
            errorwhat = CONST_ERROR_WHAT_NOTHING;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'sem') || strcmpi(varargin{inputindex}, 'standard error') || strcmpi(varargin{inputindex}, 'standard error of the mean')
            errorwhat = CONST_ERROR_WHAT_SEM;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'std') || strcmpi(varargin{inputindex}, 'standard deviation') || strcmpi(varargin{inputindex}, 'sd')
            errorwhat = CONST_ERROR_WHAT_STD;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'individuals') || strcmpi(varargin{inputindex}, 'individual')
            plotindividuals = true;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'errorcolour') || strcmpi(varargin{inputindex}, 'error colour') || strcmpi(varargin{inputindex}, 'errorcolor') || strcmpi(varargin{inputindex}, 'error color')
            errorcolour = varargin{inputindex+1};
            inputindex=inputindex+2;
        elseif strcmpi(varargin{inputindex}, 'errorlines') || strcmpi(varargin{inputindex}, 'error lines') || strcmpi(varargin{inputindex}, 'errorline') || strcmpi(varargin{inputindex}, 'error line') || strcmpi(varargin{inputindex}, 'lineerror') || strcmpi(varargin{inputindex}, 'line error')
            errorhow = CONST_ERROR_HOW_LINES;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'errorbars') || strcmpi(varargin{inputindex}, 'error bars') || strcmpi(varargin{inputindex}, 'errorbar') || strcmpi(varargin{inputindex}, 'error bar')
            errorhow = CONST_ERROR_HOW_BARS;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'area') || strcmpi(varargin{inputindex}, 'error area') || strcmpi(varargin{inputindex}, 'errorarea')
            errorhow = CONST_ERROR_HOW_AREA;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'alpha')
            alphaused = varargin{inputindex+1};
            inputindex=inputindex+2;
        elseif strcmpi(varargin{inputindex}, 'noalpha') || strcmpi(varargin{inputindex}, 'no alpha')
            alphaused = 1.0;
            inputindex=inputindex+1;
        elseif strcmpi(varargin{inputindex}, 'x') || strcmpi(varargin{inputindex}, 'xvalues') || strcmpi(varargin{inputindex}, 'x values')
            xvalues = varargin{inputindex+1};
            inputindex=inputindex+2;
        elseif strcmpi(varargin{inputindex}, 'style') || strcmpi(varargin{inputindex}, 'marker')
            style = varargin{inputindex+1};
            inputindex=inputindex+2;
        elseif inputindex==1 %by default the first extra argument is the colour (if it's not something specific)
            colour = varargin{inputindex};
            inputindex=inputindex+1;
        else
            fprintf(2, 'Warning: zplot does not understand argument %s . Ignoring it and continuing.\n', varargin{inputindex});
            inputindex=inputindex+1;
        end
    end
    
    %if input data are in a cell array, then we merge them into a single matrix, filling empty values with NaNs if needed
    if iscell(data)
        allsamesize = true;
        longest = -Inf;
        for i=1:numel(data)
            if size(data{i}, 1) > 1 && size(data{i}, 2) > 1
                error('One of the individual input dataseries was not a 1D array but a matrix. We don''t know what to do with it.\n');
            end
            if size(data{i}, 1) > 1
                data{i} = data{i}';
            end
            if length(data{i}) > longest
                longest = length(data{i});
            end
            if numel(data{i}) ~= numel(data{1})
                allsamesize = false;
            end
        end
        if allsamesize
            data = vertcat(data{:});
        else
            newdata = NaN(numel(data), longest);
            for i=1:numel(data)
                newdata(i, 1:numel(data{i})) = data{i};
            end
            data = newdata;
            clear newdata;
        end
    end
    
    %defaults
    if exist('xvalues', 'var') ~= 1
        xvalues = 1:size(data, 2);
    end
    if exist('colour', 'var') ~= 1
        colour = 'b';
    end
    if exist('style', 'var') ~= 1
        style = '-';
    end
    if exist('newfigure', 'var') ~= 1
        newfigure = true;
    end
    if exist('alphaused', 'var') ~= 1
        alphaused = 0.3; %by default the SEM areas are transparent with an alpha of 0.3. 0.0 disables transparency.
    end
    if exist('plotindividuals', 'var') ~= 1
        plotindividuals = false;
    end
    if exist('errorwhat', 'var') ~= 1 %needs to be after plotindividuals
        if plotindividuals
            errorwhat = CONST_ERROR_WHAT_NOTHING;
        else
            errorwhat = CONST_ERROR_WHAT_SEM;
        end
    end
    if exist('errorhow', 'var') ~= 1
        errorhow = CONST_ERROR_HOW_AREA;
    end
    if errorhow == CONST_ERROR_HOW_AREA
        if exist('errorcolour', 'var') ~= 1 %needs to be after colour and errorhow
            errorcolour = colour; %by default the error areas are of the same colour as the main line
        end
        if alphaused == 1 %transparency disabled; but we still want to make the error colour fainter so as to distinguish it from the main trace
            if ischar(errorcolour)
                colourmatrix = bitget(find('krgybmcw'==errorcolour)-1,1:3); %converting colour strings to RGB values - thanks to gnovice at stackoverflow
                errorcolour = 1-((1-colourmatrix)/2);
            else
                errorcolour = 1-((1-errorcolour)/2);
            end
        end
    elseif errorhow == CONST_ERROR_HOW_LINES
        if exist('errorcolour', 'var') ~= 1 %needs to be after colour and errorhow
            if ischar(colour)
                colourmatrix = bitget(find('krgybmcw'==colour)-1,1:3); %converting colour strings to RGB values - thanks to gnovice at stackoverflow
                errorcolour = 1-((1-colourmatrix)/2);
            else
                errorcolour = 1-((1-colour)/2);
            end
        elseif ischar(errorcolour) %even if error colours were explicitly defined as one of the preset chars (like 'b'), we'll make them lighter so that they stand out from the mean traces
            colourmatrix = bitget(find('krgybmcw'==errorcolour)-1,1:3); %converting colour strings to RGB values - thanks to gnovice at stackoverflow
            errorcolour = 1-((1-colourmatrix)/2);
        end
    end
    
    if newfigure
        figure;
    end
    if errorwhat ~= CONST_ERROR_WHAT_NOTHING && ~ishold(gca) %we're meant to show the extent of error, but the plot is not currently being held
        hold on; %we temporarily hold the plot so that the error shadings and the mean can be shown at the same time
        holdoffattheend = true; %and switch holding back off at the end
    else
        holdoffattheend = false;
    end
    
    datamean = NaN(1, size(data, 2));
    datastd = NaN(1, size(data, 2));
    datan = zeros(1, size(data, 2));
    datasem = NaN(1, size(data, 2));
    
    for i=1:size(data,2)
        wheregood = ~isnan(data(:, i));
        datan(i) = sum(wheregood);
        if datan(i) > 0
            datamean(i) = mean(data(wheregood, i));
            datastd(i) = std(data(wheregood, i));
            datasem(i) = datastd(i) / realsqrt(datan(i));
        else
            datamean(i) = NaN;
            datastd(i) = NaN;
            datasem(i) = NaN;
        end
    end
        
    if errorwhat ~= CONST_ERROR_WHAT_NOTHING && any(datastd>0)
        if errorwhat == CONST_ERROR_WHAT_SEM
            dataerrors = datasem;
        elseif errorwhat == CONST_ERROR_WHAT_STD
            dataerrors = datastd;
        else
            error('We were asked to plot shaded areas indicating the error, but do not understand what we are supposed to plot (SEM, STD, etc).\n');
        end
        if errorhow == CONST_ERROR_HOW_AREA
            wheregooderrors = ~isnan(datamean) & ~isnan(dataerrors);
            errorx = xvalues;
            erroryTop = datamean+dataerrors;
            erroryBot = datamean-dataerrors;
            %we specify the vertices of the patch in the following order: TL->TR->BR->BL
            %we have to take care not to include NaNs, because that would make the whole patch invalid and not show up
            patch([errorx(wheregooderrors) fliplr(errorx(wheregooderrors))], [erroryTop(wheregooderrors) fliplr(erroryBot(wheregooderrors))], errorcolour, 'FaceColor', errorcolour, 'EdgeColor', 'none', 'FaceAlpha', alphaused);
        elseif errorhow == CONST_ERROR_HOW_LINES
            plot(xvalues, datamean+dataerrors, 'color', errorcolour);
            plot(xvalues, datamean-dataerrors, 'color', errorcolour);
        end
    else
        dataerrors = NaN(1, numel(datamean));
    end
    
    if ~plotindividuals
        if errorhow ~= CONST_ERROR_HOW_BARS
            plot(xvalues, datamean, style, 'color', colour);%, 'LineWidth', 2);%, 'LineWidth', 2, 'MarkerSize', 15); %CHANGEME
        else
            errorbar(xvalues, datamean, dataerrors, style, 'color', colour, 'LineWidth', 2); %CHANGEME
        end
    else
        plot(xvalues, data', style);
    end
    
    clear dataerrors;
    
    if holdoffattheend
        hold off;
    end
    
end