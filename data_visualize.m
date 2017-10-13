% Imports data and annotations from the data files of specified subject 
% and plots it.
% Author: Ahsan
% For further details, please check this paper:
% Shahzad, Ahsan, et al. "Quantitative Assessment of Balance Impairment
% for Fall-risk Estimation using Wearable Triaxial Accelerometer." 
% IEEE Sensors Journal (2017).

clc
clear all
close all

subjectno = 7; % 1~24, except 23.
trialno = 2;  % 1 or 2.

% Add path to the DataFiles Folder
% addpath(genpath('C:\Users\Ahsan\FallRisk'));

% (Low pass) filter design
Fs = 41;
Fc = 5;
[B,A] = butter(8,Fc/(Fs/2));

test_options = {'tug','ftss','ast'};

for testi = 1:3
    testtype = test_options(testi);
    
    % IMPORT the file
    filename = strcat('pat', num2str(subjectno), char(testtype), num2str(trialno), '.dat');
    newData1 = importdata(filename);
    
    % Break the data up into a new structure with one field per column.
    colheaders = genvarname(newData1.textdata);
    for i = 1:length(colheaders)
        dataByColumn1.(colheaders{i}) = newData1.data(:, i);
    end
    
    % Create new variables in the base workspace from those fields.
    vars = fieldnames(dataByColumn1);
    for i = 1:length(vars)
        assignin('base', vars{i}, dataByColumn1.(vars{i}));
    end
    
    TimeStamp = dataByColumn1.(vars{1});
    AccelX = dataByColumn1.(vars{2});
    AccelY = dataByColumn1.(vars{3});
    AccelZ = dataByColumn1.(vars{4});
    
    % Low pass Filtering
    signal_filtX = filtfilt(B,A,AccelX);
    signal_filtY = filtfilt(B,A,AccelY);
    signal_filtZ = filtfilt(B,A,AccelZ);
    
    
    %% Extracting Annotations or markers from the file
    fid = fopen(filename);
    ctext = textscan(fid, '%s', 4, 'delimiter', '\t');
    cdata = textscan(fid, '%f %f %f %f');
    mrkrcells = textscan(fid, '%s', 'delimiter', ',')
    mrkrstringcells = mrkrcells{1};
    fclose(fid);
    
    mrkrarray = char(mrkrstringcells);
    mrkrsX = str2num(mrkrarray(8,:));
    for i = 9:length(mrkrstringcells)
        tempX = str2num(mrkrarray(i,:));
        mrkrsX = [mrkrsX  tempX];
    end
    
    %% TUGT PLOT
    if(strcmp(testtype,'tug'))
        Manual_markers = mrkrsX(1:6)
        Auto_markers = mrkrsX(8:end) % load automatically segmented markers.
                
        %   Plotting
        figure('pos',[10 40 1100 600]);
        yst = -15 ; yend = 20;
        ya = [yst  yend];
        
        hx = plot(signal_filtX);
        hold all
        hy= plot(signal_filtY);
        hz = plot(signal_filtZ);
        
        ylim([-15 20]);
        hl = legend('Ax','Ay','Az','Location','Northwest');
        
        avg1 = mean(signal_filtX);
        [pks1 ind1] = findpeaks(signal_filtX(Manual_markers(2) : Manual_markers(end-1)),'minpeakdistance',10,'minpeakheight',avg1);
        ind1 = ind1 + Manual_markers(2) ; %correction of sample number
        hcirc = plot(ind1,pks1,'o');
        
        set(hcirc, 'Marker', 'o', 'color', [.9 .3 .2], 'LineWidth', 1.5, ...
            'MarkerSize', 10);
        set(hx,  'LineWidth', 1.5);
        set(hy,  'LineWidth', 1.5);
        set(hz,  'LineWidth', 1.5);
        
        %----------------------------------------------------------
        % Annotations plotting.
        axPos = get(gca,'Position'); %# gca gets the handle to the current axes
        % axPos is [xMin,yMin,xExtent,yExtent]
        xMinMax = xlim;
        yMinMax = ylim;
        
        for i = 1:length(Manual_markers)
            XaM = [Manual_markers(i) Manual_markers(i)];
            % Normalized units w.r.t to axes
            xAnnotation = axPos(1) + ((XaM - xMinMax(1))./(xMinMax(2)-xMinMax(1))) .* axPos(3) ;
            yAnnotation = axPos(2) + ((ya - yMinMax(1))./(yMinMax(2)-yMinMax(1))) .* axPos(4) ;
            annotation('line',xAnnotation,yAnnotation, 'LineWidth', 1,'LineStyle', '--', 'color', [0.5 0.5 0.5]);
        end
        
        
        for j = 1:length(Auto_markers)
            XaA = [Auto_markers(j) Auto_markers(j)] ;
            xAnnotation = axPos(1) + ((XaA - xMinMax(1))./(xMinMax(2)-xMinMax(1))) .* axPos(3) ;
            yAnnotation = axPos(2) + ((ya - yMinMax(1))./(yMinMax(2)-yMinMax(1))) .* axPos(4) ;
            hm = annotation('line',xAnnotation,yAnnotation, 'LineWidth', 1, 'color', [0 0 .5]);
        end
        str = {'--- Manual Annotations', '__ Automatic Annotations'};
        annotation('textbox', [0.75,0.80,0.15,0.10], 'String', str);
        %-------------------------------------------------------------
        xlabel('Data Samples','Fontsize',18,'FontName','AvantGarde')
        ylabel('Acceleration (m/s^2)','Fontsize',18,'FontName','AvantGarde')
        title(strcat('TUGT of', ' Subject-',num2str(subjectno),' (Trial-', num2str(trialno),')'),'Fontsize',18);
        set(gca,'Fontsize',16, 'FontName','Helvetica')
        set(gca,...
            'Box'      , 'off',...
            'TickDir'  , 'out', ...
            'TickLength', [.02 .02],...
            'XMinorTick', 'on',...
            'YMinorTick' , 'on',...
            'YGrid'   , 'off', ...
            'XColor'  ,[.3 .3 .3], ...
            'YColor', [.3 .3 .3],...
            'LineWidth' , 1);
        % print -dtiffn TUGT_IEEE_NEWb.tiff
    end
    
    %% AST PLOT
    if(strcmp(testtype,'ast'))
        Manual_markers = mrkrsX(1:9);
        Auto_markers = mrkrsX(11:end); % load automatically segmented markers.
        
        %   Plotting
        figure('pos',[610 40 1100 600]);
        yst = -15 ; yend = 20;
        ya = [yst  yend];
        
        hx = plot(signal_filtX);
        hold all
        hy= plot(signal_filtY);
        hz = plot(signal_filtZ);
        
        ylim([-15 20]);
        hl = legend('Ax','Ay','Az','Location','Northwest');
        set(hx,  'LineWidth', 1.5);
        set(hy,  'LineWidth', 1.5);
        set(hz,  'LineWidth', 1.5);
        
        %----------------------------------------------------------
        % Annotations plotting.
        axPos = get(gca,'Position');
        xMinMax = xlim;
        yMinMax = ylim;
        
        for i = 1:length(Manual_markers)
            XaM = [Manual_markers(i) Manual_markers(i)] ;
            % Normalized units w.r.t to axes
            xAnnotation = axPos(1) + ((XaM - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);
            yAnnotation = axPos(2) + ((ya - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);
            annotation('line',xAnnotation,yAnnotation, 'LineWidth', 1,'LineStyle', '--', 'color', [0.5 0.5 0.5]);
        end
        
        for j = 1:length(Auto_markers)
            XaA = [Auto_markers(j) Auto_markers(j)] ;
            xAnnotation = axPos(1) + ((XaA - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);
            yAnnotation = axPos(2) + ((ya - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);
            hm = annotation('line',xAnnotation,yAnnotation, 'LineWidth', 1, 'color', [0 0 .5]);
        end
        str = {'--- Manual Annotations', '__ Automatic Annotations'};
        annotation('textbox', [0.75,0.80,0.15,0.10], 'String', str);
        %-------------------------------------------------------------
        xlabel('Data Samples','Fontsize',18,'FontName','AvantGarde')
        ylabel('Acceleration (m/s^2)','Fontsize',18,'FontName','AvantGarde')
        title(strcat('AST of', ' Subject-',num2str(subjectno),' (Trial-', num2str(trialno),')'),'Fontsize',18);
        set(gca,'Fontsize',16, 'FontName','Helvetica')
        set(gca,...
            'Box'      , 'off',...
            'TickDir'  , 'out', ...
            'TickLength', [.02 .02],...
            'XMinorTick', 'on',...
            'YMinorTick' , 'on',...
            'YGrid'   , 'off', ...        %'xtick', 0:50:450,...
            'XColor'  ,[.3 .3 .3], ...
            'YColor', [.3 .3 .3],...
            'LineWidth' , 1);
        % print -dtiffn AST_IEEE_NEWa.tiff
    end
    
    %% FTSS PLOT
    if(strcmp(testtype,'ftss'))
        Manual_markers = mrkrsX(1:6);
        Auto_markers = mrkrsX(8:end); % load automatically segmented markers.
        
        %   Plotting
        figure('pos',[410 440 1100 600]);
        yst = -15 ; yend = 20;
        ya = [yst  yend];
        
        hx = plot(signal_filtX);
        hold all
        hy= plot(signal_filtY);
        hz = plot(signal_filtZ);
        
        % xlim([0 600]);
        ylim([-15 20]);
        hl = legend('Ax','Ay','Az','Location','Northwest');
        set(hx,  'LineWidth', 1.5);
        set(hy,  'LineWidth', 1.5);
        set(hz,  'LineWidth', 1.5);
        
        %----------------------------------------------------------
        % Annotations plotting.
        axPos = get(gca,'Position');
        xMinMax = xlim;
        yMinMax = ylim;
        
        for i = 1:length(Manual_markers)
            XaM = [Manual_markers(i) Manual_markers(i)] ;
            % Normalized units w.r.t to axes
            xAnnotation = axPos(1) + ((XaM - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);
            yAnnotation = axPos(2) + ((ya - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);
            annotation('line',xAnnotation,yAnnotation, 'LineWidth', 1,'LineStyle', '--', 'color', [0.5 0.5 0.5]);
        end
        
        for j = 1:length(Auto_markers)
            XaA = [Auto_markers(j) Auto_markers(j)] ;
            xAnnotation = axPos(1) + ((XaA - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);
            yAnnotation = axPos(2) + ((ya - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);
            hm = annotation('line',xAnnotation,yAnnotation, 'LineWidth', 1, 'color', [0 0 .5]);
        end
        str = {'--- Manual Annotations', '__ Automatic Annotations'};
        annotation('textbox', [0.75,0.80,0.15,0.10], 'String', str);
        %-------------------------------------------------------------
        xlabel('Data Samples','Fontsize',18,'FontName','AvantGarde')
        ylabel('Acceleration (m/s^2)','Fontsize',18,'FontName','AvantGarde')
        title(strcat('FTSS of', ' Subject-',num2str(subjectno),' (Trial-', num2str(trialno),')'),'Fontsize',18);
        %     set(hl,'fontsize', 16);
        %     uistack(hl,'top');
        set(gca,'Fontsize',16, 'FontName','Helvetica')
        set(gca,...
            'Box'      , 'off',...
            'TickDir'  , 'out', ...
            'TickLength', [.02 .02],...
            'XMinorTick', 'on',...
            'YMinorTick' , 'on',...
            'YGrid'   , 'off', ...
            'XColor'  ,[.3 .3 .3], ...
            'YColor', [.3 .3 .3],...
            'LineWidth' , 1);
        % print -dtiffn FTSS_IEEE_NEWa.tiff
    end
end


