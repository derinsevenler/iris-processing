%%% This code works on a stack of n monocolor dry images. 
%% =============================================================================================
clc
%clear all
close all
% Get the mirror image file info
[file, folder] = uigetfile('*.*', 'Select the mirror file');
mirFile= [folder filesep file];

% Get the tiff Image or images if you want to do a full slide
[dataFile, dataFolder]= uigetfile('*.*', 'Select the 4 files (TIFF image stack also)', 'MultiSelect', 'on');

if ischar(dataFile) == 1
    numberOfFiles = 1;
else
    numberOfFiles = numel(dataFile);
end

%% open, crop the ROI, and align all images %%%
for i = 1:numberOfFiles

if ischar(dataFile) == 1
    tifFile = fullfile(dataFolder, dataFile);
else
    tifFile= fullfile(dataFolder, dataFile{i});
end

%number of timesteps
info=imfinfo(tifFile);
numIm=numel(info);


%Alignment of each image
color=1;
nColor=1;
im1 = imread(tifFile, color);
mir=imread(mirFile,1);
im1=double(im1)./double(mir);

%Select the regions of each image you want to analyze. These will be
%aligned and concatenated.
j = figure('Name','Please select the FOV you want to use from this image ');
[im1, cropFOVCord] = imcrop(im1);
close(j);
alignedBlocks{i}(:,:,1) = im1;
imageSegments{i}(:,:,1) = im1;


%%%Perform initial alignment over full FOV
for channel = 2:numIm   
    I = imread(tifFile,channel);
    im=double(I)./double(mir);
    im = imcrop(im, cropFOVCord);
    [Ial,tform{i}{channel}]=features(im1,im);
 
    alignedBlocks{i}(:,:,channel) = Ial;
    imageSegments{i}(:,:,channel) = im;
    progressbar(channel/numIm)
end


% %stitch images into a full slide
% slide = imageStitch(alignedBlocks);
% %im1 = slide(:,:,1);
% 
% %%%View full FOV to count how many blocks to be analyzed.
% d = figure('Name', 'This is the image you will analyze');
% imshow(im1, median(im1(:))*[0.8 1.2]);
% numberofblocks = inputdlg('how many blocks do you want to analyze in this image?');
% close(d);
% 
% %% Check alignment and preform analysis for each block in the image
% for blocknumber = 1:str2num(numberofblocks{1});
    clear align Ial
%     
% e = figure('Name',['Please select block ' num2str(blocknumber) 'to analyze']);
% [im1Small, cropCord] = imcrop(im1);
% close(e);

f=figure('Name','Please select a region of bare Si');
[~, selfRefRegion] = imcrop(im1);
close(f);




for channel = 2:numIm   
 
    Ial = Alignmentchecker(im1, alignedBlocks{i}(:,:,channel));
    
    sRef = imcrop(Ial, selfRefRegion);
    Ialpost= Ial./median(sRef(:));
    alignedBlocks{i}(:,:,channel)=Ialpost;
    progressbar(channel/numIm)
end

sRef=imcrop(im1,selfRefRegion); 
imageSegments{i}(:,:,1) = imageSegments{i}(:,:,1)./median(sRef(:));
alignedBlocks{i}(:,:,1) = alignedBlocks{i}(:,:,1)./median(sRef(:));
im1Old=alignedBlocks{i}(:,:,1);

%% Find spots and measure their values.
%%%Detect spots 

%%% filt=boxcarAv(align(:,:,:,color)); %% to be used for bigger
%%% stacks. 
 
 
%Find features that look like spots
     %filt=align;
     if color==1
         numSpots=1; 
         minimum=10;
         maximum=20;
         
         for n = 1:numSpots
              
    
               g=figure('Name','crop one region containing all the spots you wish to analyze');
               [spotBlock, spotBlockRect] = imcrop(im1Old, median(double(im1Old(:)))*[.8, 1.2]); 
               close(g);
               
               spotad=imadjust(spotBlock);
               level=graythresh(spotad);
               binary=im2bw(spotad,level);
               f=0;
              [center,rad,minimum,maximum]= CircleDet(binary,minimum,maximum,f); 
         end
     end

      
%Spot check to only include spots that match the grid and calculate spot
%values.
progressbar('timesteps','Spot Measurements') 
      for channel=1:numIm      
            
            %Spot check: discard spots that do not match grid
            if channel==1
             [center,rad,row,col,gridx,gridy]=GridSpot2(center,rad,spotBlock,spotBlockRect);
             %sorting confirmed spots: get the grid index of each spot
             matxy=sorting(center,rad,gridx,gridy,row,col);
             
             %Create spot mask
             FOVSpotMask(:,:,channel) = spotMask(im1, rad, center(:,2), center(:,1), 0.8);
             
             %Create the annulus mask
             FOVAnnulusMask(:,:,channel) = annulusMask(im1, rad, center(:,2), center(:,1), 1.3);
             
            
            else
                FOVSpotMask(:,:,channel) = imwarp(FOVSpotMask(:,:,1),tform{channel},'OutputView',outputView);
                FOVAnnulusMask(:,:,channel) = imwarp(FOVAnnulusMask(:,:,1),tform{channel},'OutputView',outputView);
            end
     %%       
            spotLabels(:,:,channel) = bwlabel(FOVSpotMask(:,:,channel));
            annulusLabels(:,:,channel) = bwlabel(FOVAnnulusMask(:,:,channel));
            
            spotMed = MaskMeasure(imageSegments{i}(:,:,channel), spotLabels(:,:,channel), gridx, gridy);
            annulusMed = MaskMeasure(imageSegments{i}(:,:,channel), annulusLabels(:,:,channel), gridx, gridy);
            
           
            
            
 %%   %Calculate the value of each spot and annulus
    for g=1:col
              centCol=matxy(1:row,1:2,g);
              radCol=matxy(1:row,3,g);
              [annulus.heights(1:row,g,channel),spotsTemp.heights{blocknumber}(1:row,g,channel)]= spotDet(filt(:,:,channel),centCol,radCol,spotBlockRect,channel,row);
              progressbar([],g/col)
    end  
     progressbar(channel/numIm, [])
      end
%Find LUT if this is the first block analyzed of this slide 
if blocknumber == 1
    [lutFile, lutFolder] = uigetfile('*.mat', 'Select the results file with the lookup table you wish to use');
    lutF = load([lutFolder filesep lutFile]);
    results.bestColor = lutF.results.bestColor;
    bestColor=lutF.results.bestColor;
    LUT=lutF.results.LUT;
end

%Apply LUT to spots and annulus and calculate difference.
spotsLUT= interp1(LUT(:,2), LUT(:,1), spotsTemp.heights{blocknumber}, 'nearest', 0);
annulusLUT= interp1(LUT(:,2), LUT(:,1), annulus.heights, 'nearest', 0);

Difftemp{blocknumber}=(annulusLUT-spotsLUT)*-1;
end
%end

%% reformat data if the entire slide was analyzed at once (ie number of blocks = 1)
if str2num(numberofblocks{1}) == 1
    %gather input data on size of blocks
    default = {'16', '10', '10'};
    prompt = {'how many blocks did you just analyze?', 'rows per block', 'columns per block'};
    format=inputdlg(prompt,'format of slide', 1, default);
    numberOfBlocks = str2num(format{1});
    rows = str2num(format{2});
    columns = str2num(format{3});
    
    %rotate such that the left side is the top
    Difftemp{1} = rot90(Difftemp{1}, 3);
    Diff = reformatData(Difftemp{1}, numberOfBlocks, rows, columns);
    
    spotsTemp.heights{1} = rot90(spotsTemp.heights{1},3);
    spots = reformatData(spotsTemp.heights{1}, numberOfBlocks,rows,columns);
    
else
    %if it was more than one block, apply a blockwise rotation to match
    %mcgill's printer orientation.
    for i = 1: str2num(numberofblocks{1})
        Diff{i} = rot90(Difftemp{i}, 3);
        spots{i} = rot90(spotsTemp.heights{i},3);
    end
    
    h = warndlg('The data in each block was rotated 90 degrees clockwise to match McGill"s inkjet printer orientation.')
    
end

% % %%===============================================================================================
%% display and save results
clear results  
results.slide = slide;
results.spotsNet = Diff;
results.spotsRaw = spots;


saveName='results.mat';
[filename, pathname] = uiputfile(saveName, 'Save results as');
save([pathname filesep filename], 'results');



