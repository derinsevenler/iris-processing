%%% This code works on a stack of n monocolor dry images.
%% =============================================================================================
clc
clearvars
close all
%
% Get the mirror image file info
[mirror.file, mirror.folder] = uigetfile('*.*', 'Select the mirror file');
mirror.path= [mirror.folder filesep mirror.file];

% Get the tiff Image or images if you want to do a full slide
[data.File, data.Folder]= uigetfile('*.*', 'Select the 4 files (TIFF image stack also)', 'MultiSelect', 'on');

if ischar(data.File) == 1
    numberOfFiles = 1;
else
    numberOfFiles = numel(data.File);
end

%tracker for # of blocks
foo = 1;

%% open, crop the ROI, and align all images %%%
for i = 1:numberOfFiles
    
    if ischar(data.File) == 1
        data.Path = fullfile(data.Folder, data.File);
    else
        data.Path= fullfile(data.Folder, data.File{i});
    end
    
    %number of timeSteps
    info=imfinfo(data.Path);
    data.timeSteps=numel(info);
    
    
    %Alignment of each image
    color=1;
    nColor=1;
    data.image = imread(data.Path, color);
   
    if ischar(mirror.file) == 1
        mir=imread(mirror.path,1);
    else
        mir = ones(size(data.image));
        h = warndlg('No mirror was selected and thus the image was not normalized (divided by 1)');
        waitfor(h)
    end
    
    data.image=double(data.image)./double(mir);
    
    %Select the regions of each image you want to analyze. These will be
    %aligned and concatenated.
    j = figure('Name','Please select the FOV you want to use from this image ');
    [data.image, cropFOVCord] = imcrop(data.image, median(double(data.image(:)))*[.8, 1.2]);
    close(j);
    alignedBlocks{i}(:,:,1) = data.image;
    imageSegments{i}(:,:,1) = data.image;
    
    
    %%%Perform initial alignment over full FOV
    for timeStep = 2:data.timeSteps
        I = imread(data.Path,timeStep);
        im=double(I)./double(mir);
        im = imcrop(im, cropFOVCord);
        [Ial,tform{i}{timeStep}]=features(data.image,im);
        
        alignedBlocks{i}(:,:,timeStep) = Ial;
        imageSegments{i}(:,:,timeStep) = im;
        progressbar(timeStep/data.timeSteps)
    end
    

    clear align Ial

    %Selecting a silicon reference region
    f=figure('Name','Please select a region of bare Si');
    [~, selfRefRegion] = imcrop(data.image);
    close(f);

    for timeStep = 2:data.timeSteps
        
        Ial = Alignmentchecker(data.image, alignedBlocks{i}(:,:,timeStep));
        
        sRef = imcrop(Ial, selfRefRegion);
        Ialpost= Ial./median(sRef(:));
        alignedBlocks{i}(:,:,timeStep)=Ialpost;
        progressbar(timeStep/data.timeSteps)
    end
    
    sRef=imcrop(data.image,selfRefRegion);
    imageSegments{i}(:,:,1) = imageSegments{i}(:,:,1)./median(sRef(:));
    alignedBlocks{i}(:,:,1) = alignedBlocks{i}(:,:,1)./median(sRef(:));
    data.imageOld=alignedBlocks{i}(:,:,1);
    
    %% Find spots and measure their values.
    %%%Detect spots
    
    %%% filt=boxcarAv(align(:,:,:,color)); %% to be used for bigger
    %%% stacks.
    
    
    %Find features that look like spots
    %filt=align;
    if color==1

            g=figure('Name','crop one region containing all the spots you wish to analyze');
            [spotBlock, spotBlockRect] = imcrop(data.imageOld, median(double(data.imageOld(:)))*[.8, 1.2]);
            close(g);
            
            spotad=imadjust(spotBlock);
            binary = localthresh(spotad);
            [center,rad,minimum,maximum]= CircleDet(binary);
    end
    
    
    %Find LUT if this is the first block analyzed of this slide
    if i == 1
        [lutFile, lutFolder] = uigetfile('*.mat', 'Select the results file with the lookup table you wish to use');
        lutF = load([lutFolder filesep lutFile]);
        bestColor=lutF.results.bestColor;
        LUT=lutF.results.LUT;
        
        %gather input on size of spot and annulus to be analyzed %gather input data on size of blocks
        default = {'0.8', '1.2', '1.4','10','4', '10', '10'};
        prompt = {'Fraction of spot to measure', 'Min fraction diameter of annulus', 'Max fraction diameter of annulus', 'radius of corner','how many blocks are you analyzing?', 'rows per block', 'columns per block'};
        maskInfo=inputdlg(prompt,'measurement properties and slide format', 1, default);
        spotMaskSize = str2num(maskInfo{1});
        annulusMin = str2num(maskInfo{2});
        annulusMax = str2num(maskInfo{3});
        cornerSize = str2num(maskInfo{4});
        numberOfBlocks = str2num(maskInfo{5});
        columnsBlock = str2num(maskInfo{6});
        rowsBlock = str2num(maskInfo{7});
        
    end
    
%%
    %progressbar('timeSteps')
    for timeStep=1:data.timeSteps
        
        %Spot check: discard spots that do not match grid
        if timeStep==1
            [center,rad,row,col,gridx,gridy]=GridSpot2(center,rad,spotad,spotBlockRect);
            
            %Create spot mask
            FOVSpotMask{i}(:,:,timeStep) = spotMask(data.image, rad, center(:,2), center(:,1), spotMaskSize);
            
            %Create the annulus mask
            FOVAnnulusMask{i}(:,:,timeStep) = annulusMask(data.image, rad, center(:,2), center(:,1), annulusMin, annulusMax);
            
            %Create corners mask
            FOVCornerMask{i}(:,:,timeStep) = CornerMask(data.image,gridx,gridy,cornerSize, columnsBlock, rowsBlock);
            imshow(data.image+FOVCornerMask{1}(:,:,1))
            
        else
            %define inverse tranformation
            invtform{i}{timeStep} = invert(tform{i}{timeStep});
            
            %Apply tranformation to mask
            outputView = imref2d(size(FOVSpotMask{i}(:,:,1)));
            FOVSpotMask{i}(:,:,timeStep) = imwarp(FOVSpotMask{i}(:,:,1),invtform{i}{timeStep},'OutputView',outputView);
            
            %find circles centers of transformed mask
            spotad=imadjust(FOVSpotMask{i}(:,:,timeStep));
            level=graythresh(spotad);
            binary=im2bw(spotad,level);
            [center] = MaskMeasure(binary);
            
            %Define shifted grid
            [center,rad,row,col,gridx,gridy]=GridSpot2(center,rad,FOVSpotMask{i}(:,:,timeStep),row,col,imageSegments{i}(:,:,timeStep));
            
            %Define masks based on new centers
            FOVSpotMask{i}(:,:,timeStep) = spotMask(data.image, rad, center(:,2), center(:,1), spotMaskSize);
            FOVAnnulusMask{i}(:,:,timeStep) = annulusMask(data.image, rad, center(:,2), center(:,1), annulusMin, annulusMax);
            FOVCornerMask{i}(:,:,timeStep) = CornerMask(data.image,gridx,gridy,cornerSize, columnsBlock, rowsBlock);
        end

        %   Calculate the median value of each region
        [~, spotMed{i}(:,:,timeStep)] = MaskMeasure(imageSegments{i}(:,:,timeStep), FOVSpotMask{i}(:,:,timeStep), gridx, gridy);
        [~, annulusMed{i}(:,:,timeStep)] = MaskMeasure(imageSegments{i}(:,:,timeStep), FOVAnnulusMask{i}(:,:,timeStep), gridx, gridy);
        [~, cornerMed{i}(:,:,timeStep)] = CornerMaskMeasure(imageSegments{i}(:,:,timeStep), FOVCornerMask{i}(:,:,timeStep), gridx, gridy);
        
        DiffMed{i}(:,:,timeStep) = spotMed{i}(:,:,timeStep) - annulusMed{i}(:,:,timeStep);
        
        % Apply the LUT 
        spotLUT{i}(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), spotMed{i}(:,:,timeStep), 'nearest', 0);
        annulusLUT{i}(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), annulusMed{i}(:,:,timeStep), 'nearest', 0);
        cornerLUT{i}(:,:,timeStep) = interp1(LUT(:,2), LUT(:,1), cornerMed{i}(:,:,timeStep), 'nearest', 0);
        annulusDiffLUT{i}(:,:,timeStep) = spotLUT{i}(:,:,timeStep) - annulusLUT{i}(:,:,timeStep);
        cornerDiffLUT{i}(:,:,timeStep) = spotLUT{i}(:,:,timeStep) - cornerLUT{i}(:,:,timeStep);
        %progressbar(timeStep/data.timeSteps)
    end
  
    %%

    %%
%     %rotate such that the left side is the top like in the printer
%     spotMed{1} = rot90(spotMed{1}, 3);
%     annulusMed{1} = rot90(annulusMed{1}, 3);
%     DiffMed{1} = rot90(DiffMed{1}, 3);
%     spotLUT{1} = rot90(spotLUT{1}, 3);
%     annulusLUT{1} = rot90(annulusLUT{1}, 3);
%     cornerLUT{1} = rot90(cornerLUT{1}, 3);
%     annulusDiffLUT{1} = rot90(annulusDiffLUT{1}, 3);
%     cornerDiffLUT{1} = rot90(cornerDiffLUT{1}, 3);
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


