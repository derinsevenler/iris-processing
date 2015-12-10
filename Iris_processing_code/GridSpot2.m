function [center,rad,row,col,totx,toty]= GridSpot2(cent,ra,spotBlock,spotBlockRect)

%%  detect "false positive" spots and construct the grid used for spots sorting
default = {'10 10'};
numS=inputdlg('How many rows and columns of spots do you wish to analyze [nrow ncol]?', 'rows and columns', 1, default);
numS=str2num(numS{1});
row=(numS(1));
col=(numS(2));



%% Create horizontal profile
xProfile = mean(spotBlock);
f2 = figure('position',[39 346 284 73]);
plot(xProfile)
title('horizontal profile')
axis tight

%% Estimate spot spacing by autocorrelation
% Ideally the spots would be periodicaly spaced consistently printed, but
% in practice they tend to have different sizes and intensities, so the
% horizontal profile is irregular. We can use autocorrelation to enhance
% the self similarity of the profile. The smooth result promotes peak
% finding and estimation of spot spacing. The *Signal Processing Toolbox*
% allows easy computation of the autocorrelation function using the |xcov|
% command.

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
% We can use the spacing estimate to help design a filter to remove the
% background noise from the intensity profile. We do this with the
% |imtophat| function from the *Image Processing Toolbox*.  The |strel|
% command creates a simple rectangular 1D window or line shaped structuring
% element.
seLine = strel('line',estPeriod,0);
xProfile2 = imtophat(xProfile,seLine);
f4 = figure('position',[40 443 285 76]);
plot(xProfile2)
title('enhanced horizontal profile')
axis tight

%% Find peaks
minPeakWidth = median(ra) - 3*std(ra);
%maxPeakWidth = median(ra) + 3*std(ra);
[pks,xCenters] = findpeaks(xProfile2, 'NPeaks', col, 'MinPeakWidth',minPeakWidth); %'MaxPeakWidth', maxPeakWidth);
findpeaks(xProfile2, 'NPeaks', col, 'MinPeakWidth',minPeakWidth)


%% Transpose and repeat
% We just did the analysis on the vertical grid. Now we want to do the same
% for the horizontal spacing. To do this, we simply transpose the image and
% repeat all the steps used above. This time without intermediate graphics
% display commands in order to summarize the mathematical steps of this
% algorithm.

yProfile = mean(spotBlock');                        %peak profile
ac = xcov(yProfile);                        %cross correlation
p1 = diff(ac([1 1:end]));
p2 = diff(ac([1:end end]));
maxima = find(p1>0 & p2<0);                 %peak locations
estPeriod = round(median(diff(maxima)));     %spacing estimate
seLine = strel('line',estPeriod,0);
yProfile2 = imtophat(yProfile,seLine);      %background removed

[pks,yCenters] = findpeaks(yProfile2, 'NPeaks', row, 'MinPeakWidth',minPeakWidth); %'MaxPeakWidth', maxPeakWidth);
findpeaks(xProfile2, 'NPeaks', row, 'MinPeakWidth',minPeakWidth)




%% creating the center matrix
totx = repmat(xCenters',1,col);
toty = repmat(yCenters,row,1);

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
figure(3);imshow(spotBlock,median(double(spotBlock(:)))*[0.8 1.2]);
hold on
plot(totx,toty,'bo');  %% totx toty are the coordinates of the points of the calculated grid
hold on
plot(cent(:,1),cent(:,2),'go'); %%cent contains just the dectected circles that have a correspondance in the  grid
%legend('Grid','Detected','True');
%% some things I don't know
cent(:,1)=cent(:,1)+spotBlockRect(1);
cent(:,2)=cent(:,2)+spotBlockRect(2);
center=cent;
rad=ra;
totx=totx+spotBlockRect(1);
toty=toty+spotBlockRect(2);


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


