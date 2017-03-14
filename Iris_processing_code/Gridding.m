function [ xCenters, yCenters, row, col ] = Gridding( varargin )
%Gridding finds the centers of each grid of the fov in spotad
%   Detailed explanation goes here

switch nargin
    case 2
        spotad = varargin{1};
        radius = varargin{2};
    case 1
        spotad = varargin{1};
end
%user input for rows and columns of block
default = {'20 20'};
numS=inputdlg('How many rows and columns of spots do you wish to analyze [nrow ncol]?', 'rows and columns', 1, default);
numS=str2num(numS{1});
row=(numS(1));
col=(numS(2));



%% Create horizontal profile
xProfile = mean(spotad);
f2 = figure('position',[39 346 284 73]);
plot(xProfile)
title('horizontal profile')
axis tight

%% Estimate spot spacing by autocorrelation
ac = xcov(smooth(xProfile));                        %unbiased autocorrelation
f3 = figure('position',[-3 427 569 94]);
plot(ac)
s1 = diff(ac([1 1:end]));                   %left slopes
s2 = diff(ac([1:end end]));                 %right slopes
maxima = find(s1>0 & s2<0);                 %peaks
estPeriod = round(median(diff(maxima)));     %nominal spacing
hold on
plot(maxima,ac(maxima),'r^')
hold off
title('autocorrelation of profile')
axis tight

%% Remove background morphologically
seLine = strel('line',estPeriod,0);
xProfile2 = imtophat(xProfile,seLine);
xProfile3 = smooth(xProfile2, 3)';
f4 = figure('position',[40 443 285 76]);
plot(xProfile3)
title('enhanced horizontal profile')
axis tight

%% Find peaks
if nargin == 1
    minPeakWidth = 12;
    maxPeakWidth = 30;
elseif nargin == 2
    minPeakWidth = max([median(radius) - 6*std(radius), 5]);
    maxPeakWidth = median(radius) + 3*std(radius);
end
[~,xCenters] = findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth);
findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth)


%% Transpose and repeat
% We just did the analysis on the vertical grid. Now we want to do the same
% for the horizontal spacing. To do this, we simply transpose the image and
% repeat all the steps used above.

yProfile = mean(spotad');                        %peak profile
ac = xcov(smooth(yProfile));                        %cross correlation
p1 = diff(ac([1 1:end]));
p2 = diff(ac([1:end end]));
maxima = find(p1>0 & p2<0);                 %peak locations
estPeriod = round(median(diff(maxima)));     %spacing estimate
seLine = strel('line',estPeriod,0);
yProfile2 = imtophat(yProfile,seLine);      %background removed
yProfile3 = smooth(yProfile2, 3)';

f5 = figure('position',[40 443 285 76]);
[~,yCenters] = findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth); 
findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth)


end

