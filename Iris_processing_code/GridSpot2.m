%GridSpot2 compares a grid to the detected spot features and only includes
%spot features that are close to the grid.  detect "false positive" spots and construct the grid used for spots sorting

function [center,rad,row,col,totx,toty]= GridSpot2(cent,ra,spotad,varargin)

if numel(varargin) == 3
    row = varargin{1};
    col = varargin{2};
    image = varargin{3};
elseif numel(varargin) == 1
spotBlockRect = varargin{1};

%user input for rows and columns of block
default = {'20 20'};
numS=inputdlg('How many rows and columns of spots do you wish to analyze [nrow ncol]?', 'rows and columns', 1, default);
numS=str2num(numS{1});
row=(numS(1));
col=(numS(2));
end


%% Create horizontal profile
xProfile = mean(spotad);

%% Estimate spot spacing by autocorrelation


ac = xcov(xProfile);                        %unbiased autocorrelation
s1 = diff(ac([1 1:end]));                   %left slopes
s2 = diff(ac([1:end end]));                 %right slopes
maxima = find(s1>0 & s2<0);                 %peaks
estPeriod = round(median(diff(maxima)));     %nominal spacing


%% Remove background morphologically

seLine = strel('line',estPeriod,0);
xProfile2 = imtophat(xProfile,seLine);
xProfile3 = smooth(xProfile2, 3)';

%% Find peaks
minPeakWidth = max([median(ra) - 6*std(ra), 5]);
maxPeakWidth = median(ra) + 3*std(ra);

[~,xCenters] = findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.002);%, 'MaxPeakWidth', maxPeakWidth);
%findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth)



%% Transpose and repeat
% We just did the analysis on the vertical grid. Now we want to do the same
% for the horizontal spacing. To do this, we simply transpose the image and
% repeat all the steps used above.

yProfile = mean(spotad');                        %peak profile
ac = xcov(yProfile);                        %cross correlation
p1 = diff(ac([1 1:end]));
p2 = diff(ac([1:end end]));
maxima = find(p1>0 & p2<0);                 %peak locations
estPeriod = round(median(diff(maxima)));     %spacing estimate
seLine = strel('line',estPeriod,0);
yProfile2 = imtophat(yProfile,seLine);      %background removed
yProfile3 = smooth(yProfile2, 3)';


[~,yCenters] = findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.002);%, 'MaxPeakWidth', maxPeakWidth); 
%findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth)



% wxyz = 0;
% while wxyz ~= 5
%% creating the center matrix
totx = repmat(xCenters,length(yCenters),1);
toty = repmat(yCenters',1,length(xCenters));

%% Pad totx and toty to match the size of the col and row,to avoid plotting errors and show failed spot detection.
if size(totx,1)<row
    totx = padarray(totx,[row-size(totx,1), 0], NaN, 'post');
end
if size(toty,1)<row
    toty = padarray(toty,[row-size(toty,1), 0], NaN, 'post');
end
if size(totx,2)<col
    totx = padarray(totx,[0, col-size(totx,2)], NaN, 'post');
end
if size(toty,2)<col
    toty = padarray(toty,[0, col-size(toty,2)], NaN, 'post');
end


% %% Show centers of calculated spots and get user input on if it is good enough
% xy = figure('Position', [200 200 600 600], 'Name', 'Are the calculated spot centers lining up with the spots?');
% 
% % Create ok push button
% okbtn = uicontrol('Style', 'pushbutton', 'String', 'ok',...
%     'Position', [20 20 50 20],...
%     'Callback', @continueCB);
% % Create add column push button
% columnbtn = uicontrol('Style', 'pushbutton', 'String', 'add column',...
%     'Position', [390 20 100 20],...
%     'Callback', @newColumn);
% % Create add row push button
% rowbtn = uicontrol('Style', 'pushbutton', 'String', 'add row',...
%     'Position', [320 20 50 20],...
%     'Callback', @newRow);
% % Create delete row push button
% delrowbtn = uicontrol('Style', 'pushbutton', 'String', 'delete row',...
%     'Position', [230 20 80 20],...
%     'Callback', @deleteRow);
% % Create delete column push button
% delcolumnbtn = uicontrol('Style', 'pushbutton', 'String', 'delete column',...
%     'Position', [120 20 100 20],...
%     'Callback', @deleteColumn);
% imshow(spotad,median(double(spotad(:)))*[0.8 1.2]);
% hold on
% plot(totx,toty,'bo');  %% totx toty are the coordinates of the points of the calculated grid
% hold off
% 
% waitfor(xy)
% 
% if wxyz == 1
%     xCenters = sort([xCenters, xcolumn]);
% elseif wxyz == 2
%     yCenters = sort([yCenters, yrow]);
% elseif wxyz == 3
%     [~, I] = min(abs(yCenters - yrow), [] ,'omitnan');
%     yCenters(I) = [];
% elseif wxyz == 4
%      [~, I] = min(abs(xCenters - xcolumn), [] ,'omitnan');
%     xCenters(I) = [];
% end
% end


%% Kicking out all the spots that are not spots.
%%%===========================================================================
ind.x=zeros(row,col);
ind.y=zeros(row,col);

if numel(varargin) == 1 %if it is initial spot discovery be stringent
tol=1; %%tol give the radius starting from the center of the spot within the detected spots is not discarded
elseif numel(varargin) == 3 %if it is spot confirmation, just take all the spots that were there to begin with.
    tol = 2;
end
range=round(mean(ra)*tol);
incrementReal = 1;

    for r=1:row
        for c=1:col
            x=totx(r,c);
            y=toty(r,c);
            if ~isnan(x)||isnan(y);
                tempSpots = [x,y;cent];
                D = pdist(tempSpots);
                [minDist, indSpot]  = min(D(1:size(cent,1)));
                if minDist <= range 
                    realCenter(incrementReal,:)= cent(indSpot,:);
                    realRadius(incrementReal,:) = ra(indSpot,:);
                    cent(indSpot,:) = [];
                    incrementReal = incrementReal +1;
                    
                    
                end
    
            end
        end
    end


%% show the grid and the detected spots
figure(3);
if numel(varargin) == 3
    imshow(spotad+image);
else
imshow(spotad,median(double(spotad(:)))*[0.8 1.2]);
end
hold on
plot(totx,toty,'bo');  %% totx toty are the coordinates of the points of the calculated grid

plot(realCenter(:,1),realCenter(:,2),'g+'); %%realCenter contains just the dectected circles that have a correspondance in the  grid

plot(cent(:,1), cent(:,2), 'r+'); %cent contains the rejected spots
hold off

%legend('Grid','Detected','True');


%% giving the full FOV coordinates instead of the local coordinates.
if numel(varargin) == 3
    center = realCenter;
    %stick to the original order of radii if it is called using extra
    %varargin.
    rad = ra;
elseif numel(varargin) == 1
    realCenter(:,1)=realCenter(:,1)+spotBlockRect(1);
    realCenter(:,2)=realCenter(:,2)+spotBlockRect(2);
    center=realCenter;
    rad=realRadius;
    totx=totx+spotBlockRect(1);
    toty=toty+spotBlockRect(2);
end


% %% Callback functions
% 
%     function continueCB(hObject, callbackdata)
%         wxyz = 5;
%         close(xy)
%     end
%     function newColumn(hObject, callbackdata)
%         wxyz=1;
%         [xcolumn,~] = ginput(1);
%         close(xy)
%     end
%  function newRow(hObject, callbackdata)
%         wxyz=2;
%         [~,yrow] = ginput(1);
%         close(xy)
%     end
%  function deleteRow(hObject, callbackdata)
%         wxyz=3;
%         [~,yrow] = ginput(1);
%         close(xy)
%  end
% function deleteColumn(hObject, callbackdata)
%         wxyz=4;
%         [xcolumn,~] = ginput(1);
%         close(xy)
%     end
end


