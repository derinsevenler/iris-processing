%%% This code works on a folder of individual Tifs, such as those captured during a real-time experiment.
%% =============================================================================================
clc
clearvars
close all

%Select the LUT
[lutFile, lutFolder] = uigetfile('*.mat', 'Select the results file with the lookup table you wish to use');
lutF = load([lutFolder filesep lutFile]);
bestColor=lutF.results.bestColor;
LUT=lutF.results.LUT;

% Get the mirror image file info
[mirror.file, mirror.folder] = uigetfile('*.*', 'Select the mirror file');
mirror.path= [mirror.folder filesep mirror.file];

% Get the folder containing all the single images
data.folder = uigetdir('','Select the folder with the images you wish to analyze');

%Select where to save the results.
saveName='results.mat';
[filename, pathname] = uiputfile(saveName, 'Save results as');

imds = datastore(data.folder,'Type','image', 'FileExtensions','.tif');
%%
%Open first image
data.initial = readimage(imds,1);

%open mirror image
if ischar(mirror.file) == 1
    mir=imread(mirror.path,1);
else
    mir = ones(size(data.image));
    h = warndlg('No mirror was selected and thus the image was not normalized (divided by 1)');
    waitfor(h)
end

%normalize initial image by mirror
data.initial=double(data.initial)./double(mir);

%Select the regions of each image you want to analyze.
j = figure('Name','Please select the FOV you want to use from this image ');
[data.initial, cropFOVCord] = imcrop(data.initial, median(double(data.initial(:)))*[.8, 1.2]);
close(j);

%Selecting a silicon reference region
f=figure('Name','Please select a region of bare Si');
[sRef, selfRefRegion] = imcrop(data.initial);
close(f);

%normalize initial image by sRef
data.initial = data.initial./median(sRef(:));

%gather input on size of spot and annulus to be analyzed %gather input data on size of blocks
default = {'0.8', '1.2', '1.4','10','4', '10', '10'};
prompt = {'Fraction of spot to measure', 'Min fraction diameter of annulus', 'Max fraction diameter of annulus', 'radius of corner','how many blocks are you analyzing?', 'rows per block', 'columns per block'};
maskInfo=inputdlg(prompt,'measurement properties and slide format', 1, default);
spotMaskSize = str2num(maskInfo{1});
annulusMin = str2num(maskInfo{2});
annulusMax = str2num(maskInfo{3});
cornerSize = str2num(maskInfo{4});
numberOfBlocks = str2num(maskInfo{5});
columnsBlock = str2num(maskInfo{7});
rowsBlock = str2num(maskInfo{6});

%Find all the spots for the initial image
g=figure('Name','crop one region containing all the spots you wish to analyze');
[spotBlock, spotBlockRect] = imcrop(data.initial, median(double(data.initial(:)))*[.8, 1.2]);
close(g);

%Find spots
spotad=imadjust(spotBlock);
binary = localthresh(spotad);
[spot.tempCenter,spot.radius,minimum,maximum]= CircleDet(binary);

%Validate spots
[spot.validatedCenter(:,:,1),spot.validatedRadius,row,col,gridx,gridy]=GridSpot1(spot.tempCenter,spot.radius,spotad,spotBlockRect);

%Create spot mask
FOVSpotMask.initial = spotMask(data.initial, spot.validatedRadius, spot.validatedCenter(:,2,1), spot.validatedCenter(:,1,1), spotMaskSize);

%Create the annulus mask
FOVAnnulusMask.initial = annulusMask(data.initial, spot.validatedRadius, spot.validatedCenter(:,2,1), spot.validatedCenter(:,1,1), annulusMin, annulusMax);

%Create corners mask
FOVCornerMask.initial = CornerMask(data.initial,gridx,gridy,cornerSize, columnsBlock, rowsBlock);
figure(4)
imshow(data.initial+FOVCornerMask.initial)

%   Calculate the median value of each region
[~, spotMed(:,:,1), spotMean(:,:,1)] = MaskMeasure(data.initial, FOVSpotMask.initial, gridx, gridy);
[~, annulusMed(:,:,1), annulusMean(:,:,1)] = MaskMeasure(data.initial, FOVAnnulusMask.initial, gridx, gridy);
[~, cornerMed(:,:,1)] = CornerMaskMeasure(data.initial, FOVCornerMask.initial, gridx, gridy);

DiffMed(:,:,1) = spotMed(:,:,1) - annulusMed(:,:,1);
DiffMean(:,:,1) = spotMean(:,:,1) - annulusMean(:,:,1);

% Apply the LUT
spotMedLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), spotMed(:,:,1), 'nearest', 0);
spotMeanLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), spotMean(:,:,1), 'nearest', 0);
annulusMedLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), annulusMed(:,:,1), 'nearest', 0);
annulusMeanLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), annulusMean(:,:,1), 'nearest', 0);
cornerLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), cornerMed(:,:,1), 'nearest', 0);
annulusDiffLUT(:,:,1) = spotMedLUT(:,:,1) - annulusMedLUT(:,:,1);
cornerMedDiffLUT(:,:,1) = spotMedLUT(:,:,1) - cornerLUT(:,:,1);
cornerMeanDiffLUT(:,:,1) = spotMeanLUT(:,:,1) - cornerLUT(:,:,1);


%% open, crop the ROI, and align all images %%%
for timeStep = 2:length(imds.Files)
    data.current = readimage(imds,timeStep);     % Read the ith image
    
    %normalize image
    data.current=double(data.current)./double(mir);
    %crop image
    data.current = imcrop(data.current, cropFOVCord);
    %Align
    [data.aligned,tform]=features(data.initial,data.current);
    %Alignment checker
    Ial = AlignmentcheckerWet(data.initial, data.aligned);
    %normalize by ref region
    sRef = imcrop(Ial, selfRefRegion);
    data.current = data.current./median(sRef(:));
    
    %define inverse transformation
    invtform = invert(tform);
    
    %Apply tranformation to mask
    outputView = imref2d(size(FOVSpotMask.initial));
    FOVSpotMask.current = imwarp(FOVSpotMask.initial,invtform,'OutputView',outputView);
    
    %find circles centers of transformed mask
    spotad=imadjust(FOVSpotMask.current);
    level=graythresh(spotad);
    binary=im2bw(spotad,level);
    [spot.tempCenter] = MaskMeasure(binary);
    
    %Define shifted grid (it does not change the validated radius)
    [bob,spot.validatedRadius,row,col,gridx,gridy]=GridSpot2(spot.tempCenter,spot.validatedRadius,FOVSpotMask.current,row,col,data.current);
    %just doing the following line because matlab crashed
    %otherwise...
    try
        spot.validatedCenter(:,:,timeStep) = bob;
    catch
        [bob,spot.validatedRadius,row,col,gridx,gridy]=GridSpot1(spot.tempCenter,spot.validatedRadius,FOVSpotMask.current,row,col,data.current);
        spot.validatedCenter(:,:,timeStep) = bob;
    end
    
    %Define masks based on new centers
    FOVSpotMask.current = spotMask(data.current, spot.validatedRadius, spot.validatedCenter(:,2, timeStep), spot.validatedCenter(:,1, timeStep), spotMaskSize);
    FOVAnnulusMask.current = annulusMask(data.current, spot.validatedRadius, spot.validatedCenter(:,2,timeStep), spot.validatedCenter(:,1, timeStep), annulusMin, annulusMax);
    FOVCornerMask.current = CornerMask(data.current,gridx,gridy,cornerSize, columnsBlock, rowsBlock);
    
    %   Calculate the median value of each region
    [~, spotMed(:,:,timeStep), spotMean(:,:,timeStep)] = MaskMeasure(data.current, FOVSpotMask.current, gridx, gridy);
    [~, annulusMed(:,:,timeStep),annulusMean(:,:,timeStep)] = MaskMeasure(data.current, FOVAnnulusMask.current, gridx, gridy);
    [~, cornerMed(:,:,timeStep)] = CornerMaskMeasure(data.current, FOVCornerMask.current, gridx, gridy);
    
%    
%     
%     DiffMed(:,:,timeStep) = spotMed(:,:,timeStep) - annulusMed(:,:,timeStep);
%     DiffMean(:,:,timeStep) = spotMean(:,:,timeStep) - annulusMean(:,:,timeStep);
%     
%     % Apply the LUT
%     spotMedLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), spotMed(:,:,timeStep), 'nearest', 0);
%     spotMeanLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), spotMean(:,:,timeStep), 'nearest', 0);
%     annulusMedLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), annulusMed(:,:,timeStep), 'nearest', 0);
%     annulusMeanLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), annulusMean(:,:,timeStep), 'nearest', 0);
%     cornerLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), cornerMed(:,:,timeStep), 'nearest', 0);
%     annulusDiffLUT(:,:,timeStep) = spotMedLUT(:,:,timeStep) - annulusMedLUT(:,:,timeStep);
%     cornerMedDiffLUT(:,:,timeStep) = spotMedLUT(:,:,timeStep) - cornerLUT(:,:,timeStep);
%     cornerMeanDiffLUT(:,:,timeStep) = spotMeanLUT(:,:,timeStep) - cornerLUT(:,:,timeStep);
    
    progressbar(timeStep/length(imds.Files))
end
%%
%break data into arrays based on incubation blocks
    spotsRawMed = reformatData(spotMed, numberOfBlocks, rowsBlock, columnsBlock);
    cornerRawMed = reformatData(cornerMed, numberOfBlocks, rowsBlock, columnsBlock);

%     spotsRawMed = reformatData(spotMed, numberOfBlocks, rowsBlock, columnsBlock);
%     annulusRawMed = reformatData(annulusMed, numberOfBlocks, rowsBlock, columnsBlock);
%     diffRawMed = reformatData(DiffMed, numberOfBlocks, rowsBlock, columnsBlock);
%     diffRawMean = reformatData(DiffMean, numberOfBlocks, rowsBlock, columnsBlock);
%     spotsMedHeight = reformatData(spotMedLUT, numberOfBlocks, rowsBlock, columnsBlock);
%     spotsMeanHeight = reformatData(spotMeanLUT, numberOfBlocks, rowsBlock, columnsBlock);
%     annulusMedHeight= reformatData(annulusMedLUT, numberOfBlocks, rowsBlock, columnsBlock);
%     annulusMeanHeight= reformatData(annulusMeanLUT, numberOfBlocks, rowsBlock, columnsBlock);
%     cornerHeight= reformatData(cornerLUT, numberOfBlocks, rowsBlock, columnsBlock);
%     annulusdiffHeight = reformatData(annulusDiffLUT, numberOfBlocks, rowsBlock, columnsBlock);
%     cornerMeddiffHeight = reformatData(cornerMedDiffLUT, numberOfBlocks, rowsBlock, columnsBlock);
%     cornerMeandiffHeight = reformatData(cornerMeanDiffLUT, numberOfBlocks, rowsBlock, columnsBlock);

%%

%Form into a timeline and smooth
windowSize = 41;
for i = 1:size(spotsRawMed,1)
    for j = 1:size(spotsRawMed,2)
        tspotsRawMed{i,j} = reshape(spotsRawMed{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        tcornerRawMed{i,j} = reshape(cornerRawMed{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        for k =  1:size(tspotsRawMed{i,j},1)
            smoothspotsRawMed{i,j}(k,:) = smooth(tspotsRawMed{i,j}(k,:)',windowSize)';      %{blocks}(spot,timepoint) (confusing organization
            smoothcornerRawMed{i,j}(k,:) = smooth(tcornerRawMed{i,j}(k,:)',windowSize)';    %{blocks}(spot,timepoint)
        end
        %apply LUT
        smoothspotsMedLUT{i,j} = interp1(LUT(:,2), LUT(:,1), smoothspotsRawMed{i,j}, 'nearest', 0);
        smoothcornerMedLUT{i,j} = interp1(LUT(:,2), LUT(:,1), smoothcornerRawMed{i,j}, 'nearest', 0);
        smoothcornermeddiffLUT{i,j} = smoothspotsMedLUT{i,j} - smoothcornerMedLUT{i,j};
        thicknesschange{i,j} = smoothcornermeddiffLUT{i,j} - repmat(smoothcornermeddiffLUT{i,j}(:,round(windowSize/2)+1),1,size(smoothcornermeddiffLUT{i,j},2));
 
        %     tannulusRawMed{i,j} = reshape(annulusRawMed{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tdiffRawMean{i,j} = reshape(diffRawMean{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tspotsMedHeight{i,j} = reshape(spotsMedHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tspotsMeanHeight{i,j} = reshape(spotsMeanHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tannulusMedHeight{i,j} = reshape(annulusMedHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tannulusMeanHeight{i,j} = reshape(annulusMeanHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tcornerHeight{i,j} = reshape(cornerHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tannulusdiffHeight{i,j} = reshape(annulusdiffHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tcornerMeddiffHeight{i,j} = reshape(cornerMeddiffHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
        %     tcornerMeandiffHeight{i,j} = reshape(cornerMeandiffHeight{i,j}, rowsBlock * columnsBlock, length(imds.Files));
    end
end
%%
time = 1:length(imds.Files);
time = time*3;
figure
plot(time,smoothcornermeddiffLUT{1,1}')
xlabel('time (s)')
ylabel('height (nm)')
title('absolute height')

figure
plot(time,thicknesschange{1,1}')
xlabel('time (s)')
ylabel('height (nm)')
title('height change')


%%
%%reformat for final output with all the data
% results.raw.spotsMed = spotsRawMed;
% results.raw.annulusMed = annulusRawMed;
% results.raw.diffMed = diffRawMed;
% results.raw.diffMean = diffRawMean;
% results.height.spotsMed = spotsMedHeight;
% results.height.spotsMean = spotsMeanHeight;
% results.height.annulus = annulusMedHeight;
% results.height.corner = cornerHeight;
% results.height.annulusdiff = annulusdiffHeight;
% results.height.cornerMeddiff = cornerMeddiffHeight;
% results.height.cornerMeandiff = cornerMeandiffHeight;
results.height.spots = smoothspotsMedLUT;
results.height.corners = smoothcornerMedLUT;
results.height.diff = smoothcornermeddiffLUT;
results.raw.spots = tspotsRawMed;
results.raw.corners = tcornerRawMed;



%add images masks, and LUT to results file
results.LUT = LUT;
results.spotBlockRect = spotBlockRect;
results.cropFOVCord = cropFOVCord;
results.selfRefRegion = selfRefRegion;
results.datafolder = data.folder;
results.mirpath = mirror.path;




save([pathname filesep filename], 'results');


