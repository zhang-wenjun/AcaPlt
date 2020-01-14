classdef AcaPlt < matlab.mixin.Copyable
    
    properties (Constant)
        ColorSeq = [ ...
              0,   0, 255; % Blue
            200,   0,   0; % Red
            255, 140,   0; % Orange
            140,  20, 200; % Purple
              0, 160,   0; % Green
            120, 120, 255; % Light blue
            165,  42,  42; % Brown
              0,   0,   0; % Black
            ] / 255
        
        FaceColorSeq = [ ...
            160, 160, 255; % Blue
            255, 160, 160; % Red
            255, 210, 160; % Orange
            210, 170, 255; % Purple
            160, 208, 160; % Green
            200, 200, 255; % Light blue
            215, 192, 192; % Brown
            160, 160, 160; % Black
            ] / 255
        
        MDColor = { ...
            [   8,  48, 107;
              207, 225, 241 ] / 255; % B
            [   0,  68,  27;
              210, 237, 204 ] / 255; % G
            [ 134,   0,   0;
              255, 200,  86 ] / 255; % R
            };
    end
    
    properties
        FigHandle
        AxesHandles
        ColorIndices
        ActiveAxes
        Journal
    end
    
    methods
        function obj = AcaPlt(varargin)
            FigArg = varargin;
            for k = 1:length(FigArg)
                if ischar(FigArg{k})
                    if strcmpi(FigArg{k}, 'Journal')
                        obj.Journal = FigArg{k+1};
                        FigArg{k:k+1} = [];
                        break;
                    end
                end
            end
            
            if mod(nargin, 2)
                obj.FigHandle = figure(FigArg{1});
                if nargin >= 3
                    set(obj.FigHandle, FigArg{2:nargin});
                end
            else
                obj.FigHandle = figure;
                if nargin >= 2
                    set(obj.FigHandle, FigArg{:});
                end
            end
        end
        
        function subplt(self, varargin)
            ax = subplot(varargin{:});
            axInd = find(ax == self.AxesHandles);
            if isempty(axInd)
                self.AxesHandles = [self.AxesHandles, ax];
                self.ColorIndices = [self.ColorIndices, 1];
                self.ActiveAxes = length(self.AxesHandles);
            elseif length(axInd) == 1
                self.ActiveAxes = axInd;
            else
                error('AcaPlt/subplt: Repeatition in AxesHandles!');
            end
            set(ax, ...
                'NextPlot', 'add', ...
                'LineWidth', 1.2, ...
                'box', 'on', ...
                'FontName', 'Times New Roman', ...
                'FontSize', 12);
        end
        
        function plt(self, varargin)
            if nargin == 1
                error('AcaPlt/plt: At least 1 input argument is required!');
            end
            
            if isa(varargin{1}, 'matlab.graphics.axis.Axes')
                axInd = find(varargin{1} == self.AxesHandles);
                if isempty(axInd)
                    error('This Axes does NOT belong to this Figure!')
                elseif length(axInd) == 1
                    self.ActiveAxes = axInd;
                else
                    error('AcaPlt/plt: Repeatition in AxesHandles!');
                end
                args = varargin{2:end};
            else
                args = varargin;
            end
            
            curAxes = self.AxesHandles(self.ActiveAxes);
            
            if strcmp(curAxes.NextPlot, 'replace')
                self.ColorIndices(self.ActiveAxes) = 1;
            end
            
            ColorIndex = self.ColorIndices(self.ActiveAxes);
            useColorSeq = true;
            
            LineWidthArg = {'LineWidth', 1.5};
            ColorArg = {'Color', AcaPlt.ColorSeq(ColorIndex, :)};
            MarkerFaceArg = {};
            ArgNames = {'Color', 'LineStyle', 'LineWidth', 'Marker', ...
                'MarkerIndices', 'MarkerEdgeColor', 'MarkerFaceColor', ...
                'MarkerSize', 'DatetimeTickFormat', 'DurationTickFormat'};
            for k = 1:length(args)
                if ischar(args{k})
                    if strcmpi(args{k}, 'LineWidth')
                        LineWidthArg = {};
                    elseif strcmpi(args{k}, 'Color')
                        ColorArg = {};
                    elseif ~any(strcmpi(args{k}, ArgNames))
                        c = regexp(args{k}, '[bgrcmykw]');
                        if length(c) == 1
                            ColorArg = {'Color', args{k}(c)};
                            useColorSeq = false;
                        elseif ~isempty(c)
                            error('AcaPlt/plt: Only ONE color could be specified!');
                        end
                        f = regexp(args{k}, 'f');
                        if length(f) == 1
                            if useColorSeq
                                MarkerFaceArg = {'MarkerFaceColor', ...
                                    AcaPlt.FaceColorSeq(ColorIndex, :)};
                            else
                                PreSetRGB = ...
                                    AcaPlt.PreSetRGB(args{k}(c));
                                MarkerFaceArg = {'MarkerFaceColor', ...
                                    (1 - PreSetRGB) * 0.75 + PreSetRGB};
                            end
                            args{k}(f) = [];
                        elseif ~isempty(f)
                            error([ ...
                                'AcaPlt/plt: ', ...
                                'Error in color/linetype argument: ', ...
                                'multiple "f"!']);
                        end
                    end
                end
            end
            
            PltArg = [args, LineWidthArg, ColorArg, MarkerFaceArg];
            plot(PltArg{:});
            
            if useColorSeq
                self.ColorIndices(self.ActiveAxes) = ...
                    mod(self.ColorIndices(self.ActiveAxes), ...
                    size(AcaPlt.ColorSeq, 1)) + 1;
            end
        end
        
        function errbar(self, varargin)
            if nargin == 1
                error('AcaPlt/errbar: At least 1 input argument is required!');
            end
            
            if isa(varargin{1}, 'matlab.graphics.axis.Axes')
                axInd = find(varargin{1} == self.AxesHandles);
                if isempty(axInd)
                    error('AcaPlt/errbar: This Axes does NOT belong to this Figure!')
                elseif length(axInd) == 1
                    self.ActiveAxes = axInd;
                else
                    error('AcaPlt/errbar: repeatition in AxesHandles!');
                end
                args = varargin{2:end};
            else 
                args = varargin;
            end
            
            curAxes = self.AxesHandles(self.ActiveAxes);
            
            if strcmp(curAxes.NextPlot, 'replace')
                self.ColorIndices(self.ActiveAxes) = 1;
            end
            
            ColorIndex = self.ColorIndices(self.ActiveAxes);
            useColorSeq = true;
            
            LineWidthArg = {'LineWidth', 1.5};
            ColorArg = {'Color', AcaPlt.ColorSeq(ColorIndex, :)};
            MarkerFaceArg = {};
            ArgNames = {'Color', 'LineStyle', 'LineWidth', 'Marker', ...
                'MarkerIndices', 'MarkerEdgeColor', 'MarkerFaceColor', ...
                'MarkerSize', 'DatetimeTickFormat', ...
                'DurationTickFormat', 'horizontal', 'vertical', 'both'};
            for k = 1:length(args)
                if ischar(args{k})
                    if strcmpi(args{k}, 'LineWidth')
                        LineWidthArg = {};
                    elseif strcmpi(args{k}, 'Color')
                        ColorArg = {};
                    elseif ~any(strcmpi(args{k}, ArgNames))
                        c = regexp(args{k}, '[bgrcmykw]');
                        if length(c) == 1
                            ColorArg = {'Color', args{k}(c)};
                            useColorSeq = false;
                        elseif ~isempty(c)
                            error('AcaPlt/errbar: Only ONE color could be specified!');
                        end
                        f = regexp(args{k}, 'f');
                        if length(f) == 1
                            if useColorSeq
                                MarkerFaceArg = {'MarkerFaceColor', ...
                                    AcaPlt.FaceColorSeq(ColorIndex, :)};
                            else
                                PreSetRGB = ...
                                    AcaPlt.PreSetRGB(args{k}(c));
                                MarkerFaceArg = {'MarkerFaceColor', ...
                                    (1 - PreSetRGB) * 0.75 + PreSetRGB};
                            end
                            args{k}(f) = [];
                        elseif ~isempty(f)
                            error([ ...
                                'AcaPlt/errbar: ', ...
                                'Error in color/linetype argument: ', ...
                                'multiple "f"!']);
                        end
                    end
                end
            end
            
            PltArg = [args, LineWidthArg, ColorArg, MarkerFaceArg];
            errorbar(PltArg{:});
            
            if useColorSeq
                self.ColorIndices(self.ActiveAxes) = ...
                    mod(self.ColorIndices(self.ActiveAxes), ...
                    size(AcaPlt.ColorSeq, 1)) + 1;
            end
        end
        
        function mdplt(self, varargin)
            % nargs == 1: mdplt(ydata)
            % nargs == 2: mdplt(axes, ydata)
            % nargs == 2: mdplt(xdata, ydata)
            % nargs == 3: mdplt(axes, xdata, ydata)
            
            nargs = 0;
            for k = 1:length(varargin)
                if ischar(varargin{k})
                    break;
                else
                    nargs = nargs + 1;
                end
            end
            
            if nargs == 0
                error('AcaPlt/mdplt: At least 1 input argument is required!');
            elseif nargs == 1
                ydata = varargin{1};
                if ~isnumeric(varargin{1})
                    error('AcaPlt/mdplt: The ONLY input argument must be numeric!');
                elseif isvector(ydata)
                    warning('AcaPlt/mdplt: For vector AcaPlt/plt is recommended!');
                    xdata = 1:length(ydata);
                else
                    xdata = repmat((1:size(ydata, 1))', 1, size(ydata, 2));
                end
                NameValuePairs = varargin(2:end);
            elseif nargs == 2
                if isa(varargin{1}, 'matlab.graphics.axis.Axes') ...
                        && isnumeric(varargin{2})
                    axInd = find(varargin{1} == self.AxesHandles);
                    if isempty(axInd)
                        error('AcaPlt/mdplt: This Axes does NOT belong to this Figure!')
                    elseif length(axInd) == 1
                        self.ActiveAxes = axInd;
                    else
                        error('AcaPlt/mdplt: repeatition in AxesHandles!');
                    end
                    ydata = varargin{2};
                    if isvector(ydata)
                        warning('AcaPlt/mdplt: For vector AcaPlt/plt is recommended!');
                        xdata = 1:length(ydata);
                    else
                        xdata = repmat((1:size(ydata,1))',1,size(ydata,2));
                    end
                elseif isnumeric(varargin{1}) && isnumeric(varargin{2})
                    xdata = varargin{1};
                    ydata = varargin{2};
                else
                    error([ ...
                        'AcaPlt/mdplt: ', ...
                        'For 2 input arguments: ', ...
                        '    AcaPlt.mdplt(axes, ydata)', ...
                        '    AcaPlt.mdplt(xdata, ydata)']);
                end
                NameValuePairs = varargin(3:end);
            elseif nargs == 3
                if isa(varargin{1}, 'matlab.graphics.axis.Axes') ...
                        && isnumeric(varargin{2}) && isnumeric(varargin{3})
                    axInd = find(varargin{1} == self.AxesHandles);
                    if isempty(axInd)
                        error('AcaPlt/mdplt: This Axes does NOT belong to this Figure!')
                    elseif length(axInd) == 1
                        self.ActiveAxes = axInd;
                    else
                        error('AcaPlt/mdplt: repeatition in AxesHandles!');
                    end
                    xdata = varargin{2};
                    ydata = varargin{3};
                else
                    error([ ...
                        'AcaPlt/mdplt: ', ...
                        'For 3 input arguments: ', ...
                        '    AcaPlt.mdplt(axes, xdata, ydata)']);
                end
                NameValuePairs = varargin(4:end);
            else
                error('AcaPlt/mdplt: Invalid input arguments!');
            end
            
            if isvector(xdata) && isvector(ydata)
                warning('AcaPlt/mdplt: For vector AcaPlt.plt is recommended!');
            elseif isvector(xdata) && length(xdata)==size(ydata,1)
                xdata = repmat(xdata(:), 1, size(ydata,2));
            elseif all(size(xdata) == size(ydata))
            else
                error('AcaPlt/mdplt: Invalid input data!');
            end
                
            color = AcaPlt.MDColor{1};
            linestyle = '-';
            linewidth = 1.2;
            rev = false;
            
            for k = 1:length(NameValuePairs)
                if ~ischar(NameValuePairs{k})
                    continue;
                end
                
                if strcmpi(NameValuePairs{k}, 'Color')
                    color = NameValuePairs{k+1};
                    if isnumeric(color) ...
                        && size(color, 1) >= 2 && size(color, 2) == 3 ...
                        && all(color <= 1) && all(color >= 0)
                    elseif ischar(color)
                        ctemp = regexp(color, '[rgbcmykw]', 'match');
                        if length(ctemp) == 1
                            if strcmpi(ctemp{1}, 'b')
                                color = AcaPlt.MDColor{1};
                            elseif strcmpi(ctemp{1}, 'g')
                                color = AcaPlt.MDColor{2};
                            elseif strcmpi(ctemp{1}, 'r')
                                color = AcaPlt.MDColor{3};
                            else
                                error('AcaPlt/mdplt: At least 2 color is required!');
                            end
                        else
                            for c = 1:length(ctemp)
                                if c == 1
                                    color = AcaPlt.PreSetRGB(ctemp{c});
                                else
                                    color = [color; AcaPlt.PreSetRGB(ctemp{c})];
                                end
                            end
                        end
                    end
                elseif strcmpi(NameValuePairs{k}, 'LineWidth')
                    linewidth = NameValuePairs{k+1};
                elseif isempty(regexp(NameValuePairs{k}, ...
                            '[^-.:rgbcmykwi]', 'ONCE'))
                    ltemp = regexp(NameValuePairs{k}, '(--|-\.|-|:)', 'match');
                    if ~isempty(ltemp)
                        linestyle = ltemp{end};
                    end
                    if ismember('i', NameValuePairs{k})
                        rev = true;
                    end
                    ctemp = regexp(NameValuePairs{k}, '[rgbcmykw]', 'match');
                    if length(ctemp) == 1
                        if strcmpi(ctemp{1}, 'b')
                            color = AcaPlt.MDColor{1};
                        elseif strcmpi(ctemp{1}, 'g')
                            color = AcaPlt.MDColor{2};
                        elseif strcmpi(ctemp{1}, 'r')
                            color = AcaPlt.MDColor{3};
                        else
                            error('AcaPlt/mdplt: At least 2 color is required!');
                        end
                    else
                        for c = 1:length(ctemp)
                            if c == 1
                                color = AcaPlt.PreSetRGB(ctemp{c});
                            else
                                color = [color; AcaPlt.PreSetRGB(ctemp{c})];
                            end
                        end
                    end
                else
                    error('AcaPlt/mdplt: Invalid argument!');
                end
            end
            
            if rev
                color = color(end:-1:1, :);
            end
            
            NumLines = size(xdata, 2);
            x = linspace(1, NumLines, size(color, 1))';
            xi = (1:NumLines)';
            color = [ ...
                interp1(x, color(:, 1), xi, 'linear') , ...
                interp1(x, color(:, 2), xi, 'linear') , ...
                interp1(x, color(:, 3), xi, 'linear') ];
            
            curAxes = self.AxesHandles(self.ActiveAxes);
            tempNextPlot = curAxes.NextPlot;
            plot(xdata(:, 1), ydata(:, 1), ...
                'Color', color(1, :), ...
                'LineWidth', linewidth, ...
                'LineStyle', linestyle);
            curAxes.NextPlot = 'add';
            for k = 2:NumLines
                plot(xdata(:, k), ydata(:, k), ...
                    'Color', color(k, :), ...
                    'LineWidth', linewidth, ...
                    'LineStyle', linestyle);
            end
            curAxes.NextPlot = tempNextPlot;
            
        end
        
        function lgd(self, varargin)
            if length(varargin) >= 1 && isa(varargin{1}, 'matlab.graphics.axis.Axes')
                axInd = find(varargin{1} == self.AxesHandles);
                if isempty(axInd)
                    error('AcaPlt/lgd: This Axes does NOT belong to this Figure!')
                elseif length(axInd) == 1
                    self.ActiveAxes = axInd;
                else
                    error('AcaPlt/lgd: Repeatition in AxesHandles!');
                end
                args = varargin{2:end};
            else
                args = varargin;
            end
            
            curAxes = self.AxesHandles(self.ActiveAxes);
            
            InterpreterArg = {'Interpreter', 'latex'};
            for k = 1:length(args)
                if strcmpi(args{k}, 'interpreter')
                    InterpreterArg = {'Interpreter', args{k+1}};
                end
            end
            
            args = [args, InterpreterArg];
            
            legend(curAxes, args{:});
            
        end
        
        function xlabel(self, varargin)
            if isa(varargin{1}, 'matlab.graphics.axis.Axes')
                axInd = find(varargin{1} == self.AxesHandles);
                if isempty(axInd)
                    error('AcaPlt/xlabel: This Axes does NOT belong to this Figure!')
                elseif length(axInd) == 1
                    self.ActiveAxes = axInd;
                else
                    error('AcaPlt/xlabel: Repeatition in AxesHandles!');
                end
                args = varargin{2:end};
            else
                args = varargin;
            end
            
            curAxes = self.AxesHandles(self.ActiveAxes);
            
            InterpreterArg = {'Interpreter', 'latex'};
            for k = 1:length(args)
                if strcmpi(args{k}, 'interpreter')
                    InterpreterArg = {'Interpreter', args{k+1}};
                end
            end
            
            args = [args, InterpreterArg];
            
            xlabel(curAxes, args{:});
        end
        
        function ylabel(self, varargin)
            if isa(varargin{1}, 'matlab.graphics.axis.Axes')
                axInd = find(varargin{1} == self.AxesHandles);
                if isempty(axInd)
                    error('AcaPlt/ylabel: This Axes does NOT belong to this Figure!')
                elseif length(axInd) == 1
                    self.ActiveAxes = axInd;
                else
                    error('AcaPlt/ylabel: Repeatition in AxesHandles!');
                end
                args = varargin{2:end};
            else
                args = varargin;
            end
            
            curAxes = self.AxesHandles(self.ActiveAxes);
            
            InterpreterArg = {'Interpreter', 'latex'};
            for k = 1:length(args)
                if strcmpi(args{k}, 'interpreter')
                    InterpreterArg = {'Interpreter', args{k+1}};
                end
            end
            
            args = [args, InterpreterArg];
            
            ylabel(curAxes, args{:});
        end
        
        function title(self, varargin)
            if isa(varargin{1}, 'matlab.graphics.axis.Axes')
                axInd = find(varargin{1} == self.AxesHandles);
                if isempty(axInd)
                    error('AcaPlt/title: This Axes does NOT belong to this Figure!')
                elseif length(axInd) == 1
                    self.ActiveAxes = axInd;
                else
                    error('AcaPlt/title: Repeatition in AxesHandles!');
                end
                args = varargin{2:end};
            else
                args = varargin;
            end
            
            curAxes = self.AxesHandles(self.ActiveAxes);
            
            InterpreterArg = {'Interpreter', 'latex'};
            for k = 1:length(args)
                if strcmpi(args{k}, 'interpreter')
                    InterpreterArg = {'Interpreter', args{k+1}};
                end
            end
            
            args = [args, InterpreterArg];
            
            title(curAxes, args{:});
        end
        
        function holdon(self, ax)
            if nargin == 1
                curAxes = self.AxesHandles(self.ActiveAxes);
                hold(curAxes, 'on');
            elseif nargin == 2
                if isa(ax, 'matlab.graphics.axis.Axes')
                    axInd = find(ax == self.AxesHandles);
                    if isempty(axInd)
                        error('AcaPlt/holon: This Axes does NOT belong to this Figure!')
                    elseif length(axInd) == 1
                        self.ActiveAxes = axInd;
                    else
                        error('AcaPlt/holon: Repeatition in AxesHandles!');
                    end
                else
                    error('AcaPlt/holdon: Invalid input!');
                end
                curAxes = self.AxesHandles(self.ActiveAxes);
                hold(curAxes, 'on');
            else
                error('AcaPlt/holdon: Invalid input!');
            end
        end
        
        function holdoff(self, ax)
            if nargin == 1
                curAxes = self.AxesHandles(self.ActiveAxes);
                hold(curAxes, 'off');
            elseif nargin == 2
                if isa(ax, 'matlab.graphics.axis.Axes')
                    axInd = find(ax == self.AxesHandles);
                    if isempty(axInd)
                        error('AcaPlt/holoff: This Axes does NOT belong to this Figure!')
                    elseif length(axInd) == 1
                        self.ActiveAxes = axInd;
                    else
                        error('AcaPlt/holoff: Repeatition in AxesHandles!');
                    end
                else
                    error('AcaPlt/holdoff: Invalid input!');
                end
                curAxes = self.AxesHandles(self.ActiveAxes);
                hold(curAxes, 'off');
            else
                error('AcaPlt/holdon: Invalid input!');
            end
        end
        
        function xlim(~, lim)
            xlim(lim);
        end
        
        function ylim(~, lim)
            ylim(lim);
        end
            
    end
    
    methods (Static)
        function RGB = PreSetRGB(colorchar)
            switch colorchar
                case 'b'
                    RGB = [0, 0, 1];
                case 'g'
                    RGB = [0, 1, 0];
                case 'r'
                    RGB = [1, 0, 0];
                case 'c'
                    RGB = [0, 1, 1];
                case 'm'
                    RGB = [1, 0, 1];
                case 'y'
                    RGB = [1, 1, 0];
                case 'k'
                    RGB = [0, 0, 0];
                case 'w'
                    RGB = [1, 1, 1];
                otherwise
                    error('Invalid color argument!');
            end
            
        end
        
    end
    
end