%%% This code works on a stack of n monocolor dry images.
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

% Get the tiff Image or images if you want to do a full slide
data.folder = uigetdir('','Select the folder with the images you wish to analyze');

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
[spot.validatedCenter(:,:,1),spot.validatedRadius,row,col,gridx,gridy]=GridSpot2(spot.tempCenter,spot.radius,spotad,spotBlockRect);

%Create spot mask
FOVSpotMask.initial = spotMask(data.initial, spot.validatedRadius, spot.validatedCenter(:,2,1), spot.validatedCenter(:,1,1), spotMaskSize);

%Create the annulus mask
FOVAnnulusMask.initial = annulusMask(data.initial, spot.validatedRadius, spot.validatedCenter(:,2,1), spot.validatedCenter(:,1,1), annulusMin, annulusMax);

%Create corners mask
FOVCornerMask.initial = CornerMask(data.initial,gridx,gridy,cornerSize, columnsBlock, rowsBlock);
figure(4)
imshow(data.initial+FOVCornerMask.initial)

%   Calculate the median value of each region
[~, spotMed(:,:,1)] = MaskMeasure(data.initial, FOVSpotMask.initial, gridx, gridy);
[~, annulusMed(:,:,1)] = MaskMeasure(data.initial, FOVAnnulusMask.initial, gridx, gridy);
[~, cornerMed(:,:,1)] = CornerMaskMeasure(data.initial, FOVCornerMask.initial, gridx, gridy);

DiffMed(:,:,1) = spotMed(:,:,1) - annulusMed(:,:,1);

% Apply the LUT
spotLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), spotMed(:,:,1), 'nearest', 0);
annulusLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), annulusMed(:,:,1), 'nearest', 0);
cornerLUT(:,:,1) = interp1(LUT(:,2), LUT(:,1), cornerMed(:,:,1), 'nearest', 0);
annulusDiffLUT(:,:,1) = spotLUT(:,:,1) - annulusLUT(:,:,1);
cornerDiffLUT(:,:,1) = spotLUT(:,:,1) - cornerLUT(:,:,1);

%tracker for # of blocks
foo = 1;

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
    spot.validatedCenter(:,:,timeStep) = bob;
    
    %Define masks based on new centers
    FOVSpotMask.current = spotMask(data.current, spot.validatedRadius, spot.validatedCenter(:,2, timeStep), spot.validatedCenter(:,1, timeStep), spotMaskSize);
    FOVAnnulusMask.current = annulusMask(data.current, spot.validatedRadius, spot.validatedCenter(:,2,timeStep), spot.validatedCenter(:,1, timeStep), annulusMin, annulusMax);
    FOVCornerMask.current = CornerMask(data.current,gridx,gridy,cornerSize, columnsBlock, rowsBlock);
    
    %   Calculate the median value of each region
    [~, spotMed(:,:,timeStep), spotMean(:,:,timeStep)] = MaskMeasure(data.current, FOVSpotMask.current, gridx, gridy);
    [~, annulusMed(:,:,timeStep),annulusMean(:,:,timeStep)] = MaskMeasure(data.current, FOVAnnulusMask.current, gridx, gridy);
    [~, cornerMed(:,:,timeStep)] = CornerMaskMeasure(data.current, FOVCornerMask.current, gridx, gridy);
    
    DiffMed(:,:,timeStep) = spotMed(:,:,timeStep) - annulusMed(:,:,timeStep);
    DiffMean(:,:,timeStep) = spotMean(:,:,timeStep) - annulusMean(:,:,timeStep);
    
    % Apply the LUT
    spotLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), spotMed(:,:,timeStep), 'nearest', 0);
    annulusLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), annulusMed(:,:,timeStep), 'nearest', 0);
    cornerLUT(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), cornerMed(:,:,timeStep), 'nearest', 0);
    annulusDiffLUT(:,:,timeStep) = spotLUT(:,:,timeStep) - annulusLUT(:,:,timeStep);
    cornerDiffLUT(:,:,timeStep) = spotLUT(:,:,timeStep) - cornerLUT(:,:,timeStep);
    
    progressbar(timeStep/length(imds.Files))
end







    %%
    %break data into arrays based on incubation blocks
    spotsRaw = reformatData(spotMed{i}, numberOfBlocks, rowsBlock, columnsBlock);
    annulusRaw = reformatData(annulusMed{i}, numberOfBlocks, rowsBlock, columnsBlock);
    diffRaw = reformatData(DiffMed{i}, numberOfBlocks, rowsBlock, columnsBlock);
    spotsHeight = reformatData(spotLUT{i}, numberOfBlocks, rowsBlock, columnsBlock);
    annulusHeight= reformatData(annulusLUT{i}, numberOfBlocks, rowsBlock, columnsBlock);
    cornerHeight= reformatData(cornerLUT{i}, numberOfBlocks, rowsBlock, columnsBlock);
    annulusdiffHeight = reformatData(annulusDiffLUT{i}, numberOfBlocks, rowsBlock, columnsBlock);
    cornerdiffHeight = reformatData(cornerDiffLUT{i}, numberOfBlocks, rowsBlock, columnsBlock);

    %reformat for final output with all the data
    for syzygy = 1:numberOfBlocks
        results.raw.spots{foo + syzygy-1} = spotsRaw{syzygy};
        results.raw.annulus{foo + syzygy-1} = annulusRaw{syzygy};
        results.raw.diff {foo + syzygy-1} = diffRaw{syzygy};
        results.height.spots{foo + syzygy-1} = spotsHeight{syzygy};
        results.height.annulus{foo + syzygy-1} = annulusHeight{syzygy};
        results.height.corner{foo + syzygy-1} = cornerHeight{syzygy};
        results.height.annulusdiff{foo + syzygy-1} = annulusdiffHeight{syzygy};
        results.height.cornerdiff{foo + syzygy-1} = cornerdiffHeight{syzygy};
    end

    %increment block tracker
    foo = foo+numberOfBlocks;

    %add images masks, and LUT to results file
    %results.images{i} = imageSegments{i};
    %results.spotMasks{i} = FOVSpotMask{i};
    %results.annulusMasks{i} = FOVAnnulusMask{i};
    results.LUT = LUT;
    results.spotBlockRect = spotBlockRect;
    results.cropFOVCord = cropFOVCord;
    results.selfRefRegion = selfRefRegion;
    results.dataPath = data.Path;
    results.mirpath = mirror.path;

end


saveName='results.mat';
[filename, pathname] = uiputfile(saveName, 'Save results as');
save([pathname filesep filename], 'results');


