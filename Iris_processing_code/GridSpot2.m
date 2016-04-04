%GridSpot2 compares a grid to the detected spot features and only includes
%spot features that are close to the grid.  detect "false positive" spots and construct the grid used for spots sorting

function [center,rad,row,col,totx,toty]= GridSpot2(cent,ra,spotBlock,varargin)

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
xProfile = mean(spotBlock);
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
minPeakWidth = median(ra) - 6*std(ra);
maxPeakWidth = median(ra) + 3*std(ra);
[~,xCenters] = findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.004);%, 'MaxPeakWidth', maxPeakWidth);
findpeaks(xProfile3, 'NPeaks', col, 'MinPeakWidth',minPeakWidth, 'MinPeakProminence', 0.004);%, 'MaxPeakWidth', maxPeakWidth)


%% Transpose and repeat
% We just did the analysis on the vertical grid. Now we want to do the same
% for the horizontal spacing. To do this, we simply transpose the image and
% repeat all the steps used above.

yProfile = mean(spotBlock');                        %peak profile
ac = xcov(yProfile);                        %cross correlation
p1 = diff(ac([1 1:end]));
p2 = diff(ac([1:end end]));
maxima = find(p1>0 & p2<0);                 %peak locations
estPeriod = round(median(diff(maxima)));     %spacing estimate
seLine = strel('line',estPeriod,0);
yProfile2 = imtophat(yProfile,seLine);      %background removed
yProfile3 = smooth(yProfile2, 3)';

[~,yCenters] = findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.004);%, 'MaxPeakWidth', maxPeakWidth); 
findpeaks(yProfile3, 'NPeaks', row, 'MinPeakWidth',minPeakWidth,'MinPeakProminence', 0.004);%, 'MaxPeakWidth', maxPeakWidth)




%% creating the center matrix
totx = repmat(xCenters,row,1);
toty = repmat(yCenters',1,col);

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


%% Show centers of calculated spots and get user input on if it is good enough
xy = figure('Position', [200 200 500 500], 'Name', 'Are the calculated spot centers lining up with the spots?');

% Create ok push button
okbtn = uicontrol('Style', 'pushbutton', 'String', 'ok',...
    'Position', [20 20 50 20],...
    'Callback', @continueCB);
% Create ok push button
nobtn = uicontrol('Style', 'pushbutton', 'String', 'no',...
    'Position', [420 20 50 20],...
    'Callback', @startOver);
imshow(spotBlock,median(double(spotBlock(:)))*[0.8 1.2]);
hold on
plot(totx,toty,'bo');  %% totx toty are the coordinates of the points of the calculated grid
hold off

waitfor(xy)
close(f2)
close(f3)
close(f4)



%% Perform manual gridding only if automatic gridding failed

if xyz == 1
    clear totx toty
    %% save in posDry the coordinates of the first row of spots
    
    
    for z=1:(col+1)
        if z==col+1
            p=figure('Name','Select the center of the first spot of the second row you want to analyze');
        else
            p=figure('Name', 'Select the center of each spot of the first row you want to analyze');
        end
        imshow(spotBlock,median(double(spotBlock(:)))*[0.8 1.2]);
        g=impoint(gca);
        pause(0.5);
        posDry(z,:)=getPosition(g);
        delete(p);
        close(gcf);
    end
    %
    %% distance between spots
    p1=posDry(1,:);
    p2=posDry(col+1,:);
    distx=p2(1)-p1(1);
    disty=p2(2)-p1(2);
    %
    % %% create the grid
    
    if distx==0
        addx=zeros(1,row);
    else
        if row>1
            addx=[0:distx:distx*(row-1)];
        else
            addx=0;
        end
    end
    
    if disty==0
        addy=zeros(1,row);
    else
        if row>1
            addy=[0:disty:disty*(row-1)];
        else
            addy=0;
        end
    end
    
    for j=1:col
        %% coordinates of the spots on the other rows
        totx(j,1:length(addx))=posDry(j,1)+addx;
        toty(j,1:length(addy))=posDry(j,2)+addy;
    end
    
    totx=totx';
    toty=toty';
    
end






%% Kicking out all the spots that are not spots.
%%%===========================================================================
ind.x=zeros(row,col);
ind.y=zeros(row,col);

tol=2; %%tol give the radius starting from the center of the spot within the detected spots is not discarded
range=round(mean(ra)*tol);

for z=1:length(cent(:,1));
    xC=cent(z,1);
    yC=cent(z,2);
    for r=1:row
        for c=1:col
            x=totx(r,c);
            y=toty(r,c);
            if (xC<x+range&&xC>x-range&&yC<y+range&&yC>y-range)==1
                fl(r,c,z)=1;
            else
                fl(r,c,z)=0;
            end
        end
    end
    if (find(fl(:,:,z)==1))~=0
        log(z)=1;
    else
        log(z)=0;
    end
end

idxF=find(log==0);
cent(idxF,:)=[];
ra(idxF,:)=[];




%% show the grid and the detected spots
figure(3);
if numel(varargin) == 3
    imshow(spotBlock+image);
else
imshow(spotBlock,median(double(spotBlock(:)))*[0.8 1.2]);
end
hold on
plot(totx,toty,'bo');  %% totx toty are the coordinates of the points of the calculated grid

plot(cent(:,1),cent(:,2),'go'); %%cent contains just the dectected circles that have a correspondance in the  grid
hold off

%legend('Grid','Detected','True');


%% giving the full FOV coordinates instead of the local coordinates.
if numel(varargin) == 3
    center = cent;
    rad = ra;
elseif numel(varargin) == 1
    cent(:,1)=cent(:,1)+spotBlockRect(1);
    cent(:,2)=cent(:,2)+spotBlockRect(2);
    center=cent;
    rad=ra;
    totx=totx+spotBlockRect(1);
    toty=toty+spotBlockRect(2);
end


%% Callback functions

    function continueCB(hObject, callbackdata)
        xyz=0;
        close(xy)
    end
    function startOver(hObject, callbackdata)
        xyz=1;
        close(xy)
    end

end


