function [ binary ] = localthresh( spotad )
%localthresh finds the rows and columns of each spot, then calculates the thresholded image based on local thresholds around each spot
%   First, the function determines the rows and columns of each spot. Then,
%   it forms a grid around each spot, and calculates the local threshold
%   for each grid element, stitching the full binary image stitch by
%   stitch.



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
ac = xcov(xProfile);                        %unbiased autocorrelation
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
minPeakWidth = 15;
maxPeakWidth = 30;
[~,xCenters] = findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth);
findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth)


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

f5 = figure('position',[40 443 285 76]);
[~,yCenters] = findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth); 
findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.02);%, 'MaxPeakWidth', maxPeakWidth)

%split the image into ROIs with 1 spot per ROI based on the spot centers
%found above
%x divisions
diff_x = diff(xCenters);
x = ones(length(xCenters)+1,1);
x(2:end-1) = xCenters(1:end-1) + diff_x/2;
x(end) = size(spotad,2);
x = round(x);

%Y divisions
diff_y = diff(yCenters);
y = ones(length(yCenters)+1, 1);
y(2:end-1) = yCenters(1:end-1) + diff_y/2;
y(end) = size(spotad,1);
y = round(y);

%Calculate threshold of image ROI by ROI such that low signal spots are
%included.
for i = 1:length(y)-1
    for j = 1:length(x)-1
        level = graythresh(spotad(y(i):y(i+1),x(j):x(j+1)));
        binary(y(i):y(i+1),x(j):x(j+1)) = im2bw(spotad(y(i):y(i+1),x(j):x(j+1)),level);
    end
end



end

