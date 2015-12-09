%%% This code works on a stack of n monocolor dry images. 
%% =============================================================================================
clc
clear all
% Get the mirror image file info

[file, folder] = uigetfile('*.*', 'Select the mirror file (TIFF image stack also)');
mirFile= [folder filesep file];

% Get the tiff Image
[file, folder] = uigetfile('*.*', 'Select the data file (TIFF image stack also)');
tifFile= [folder filesep file];

info=imfinfo(tifFile);
numIm=numel(info);

%% ===================================================================================================================
%%%Alignment
color=1;
nColor=1;
im1 = imread(tifFile, color);
mir=imread(mirFile,1);
im1=double(im1)./double(mir);

%%%Select the FOV you want to use for the full analysis (this helps with
%%%the feature alignment. Different crops will make it work.
j = figure('Name','Please select the full FOV you want to use for this analysis ');
[im1, cropFOVCord] = imcrop(im1);
close(j);
alignFullFOV(:,:,1) = im1;


%%%Perform initial alignment over full FOV
for channel = 2:numIm   
    I = imread(tifFile,channel);
    im=double(I)./double(mir);
    %im = imcrop(im,cropFOVCord);
    [Ial]=features(im1,im);
 
    alignFullFOV(:,:,channel)=Ial;
    progressbar(channel/numIm)
end

%%%View full FOV to count how many blocks to be analyzed.
d = figure('Name', 'This is the image you will analyze');
imshow(im1, median(im1(:))*[0.8 1.2]);
numberofblocks = inputdlg('how many blocks do you want to analyze in this image?');
close(d);
%%
%%%Check alignment and preform analysis for each block in the image
for blocknumber = 1:str2num(numberofblocks{1});
    clear align Ial
    
e = figure('Name',['Please select block ' num2str(blocknumber) 'to analyze']);
[im1Small, cropCord] = imcrop(im1);
close(e);

f=figure('Name','Please select a region of bare Si');
[~, selfRefRegion] = imcrop(im1Small);
close(f);

%%
for channel = 2:numIm   
    imsmall = imcrop(alignFullFOV(:,:,channel), cropCord);
 
    [Ial] = Alignmentchecker(im1Small, imsmall);
    
    sRef = imcrop(Ial, selfRefRegion);
    Ialpost= Ial./median(sRef(:));
    align(:,:,channel)=Ialpost;
    progressbar(channel/numIm)
end

align(:,:,1)= im1Small./median(sRef(:));
im1Old=align(:,:,1);

%% ===========================================================================================================
% %%Detect spots 

  %%% filt=boxcarAv(align(:,:,:,color)); %% to be used for bigger
 %%% stacks. 
     filt=align;
     if color==1
         numSpots=1; 
         minimum=10;
         maximum=20;
         
         for n = 1:numSpots
              
    
               g=figure('Name','crop one region containing all the spots you wish to analyze');
               [spotR, spotRect(n,:)] = imcrop(im1Old, median(double(im1Old(:)))*[.8, 1.2]); 
               close(g);
               
               spotad=imadjust(spotR);
               level=graythresh(spotad);
               binary=im2bw(spotad,level);
               f=0;
              [center,rad,minimum,maximum]= CircleDet(binary,minimum,maximum,f); 
         end
      end
%   
% % %%%% Calculate spots and annulus values
% %  
      for channel=1:numIm      
        
            if channel==1
             [center,rad,centerOld,radOld,row,col,gridx,gridy]=GridSpot2(center,rad,spotR,spotRect);
          %%% sorting detect spots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          matxy=sorting(center,rad,gridx,gridy,row,col);
       
            end
       
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
     for g=1:col
              centCol=matxy(1:row,1:2,g);
              radCol=matxy(1:row,3,g);
              [annulus.heights(1:row,g,channel),spots.heights{blocknumber}(1:row,g,channel)]= spotDet(filt(:,:,channel),centCol,radCol,spotRect,channel,row);
     end  
      end
 
      
[lutFile, lutFolder] = uigetfile('*.mat', 'Select the results file with the lookup table you wish to use');
lutF = load([lutFolder filesep lutFile]);
results.bestColor = lutF.results.bestColor;
bestColor=lutF.results.bestColor;
LUT=lutF.results.LUT;


spotsLUT= interp1(LUT(:,2), LUT(:,1), spots.heights{blocknumber}, 'nearest', 0);
annulusLUT= interp1(LUT(:,2), LUT(:,1), annulus.heights, 'nearest', 0);

Diff{blocknumber}=(annulusLUT-spotsLUT)*-1;
end
% % %%===============================================================================================
%% display and save results
   
%    name1=strcat('Diff.xlsx');
%    name2=strcat('Annulus.xlsx');
%    name3=strcat('Spots.xlsx');
    
%    for g=1:row
%    numSheet=strcat('column',num2str(g));    
%    S=Diff(:,:,g,color);
%    xlswrite(name1,S,numSheet);
%    R=spots.heights(:,:,g,color);  
%    xlswrite(name3,R,numSheet);
%    A=annulus.heights(:,:,g,color);
%    xlswrite(name2,A,numSheet);
%   end 


%%%% save mat
%saveName='images.mat';
%[filename, pathname] = uiputfile(saveName, 'Save results as');
%save([pathname filesep filename], 'imLUT');

saveName='spotsRaw.mat';
[filename, pathname] = uiputfile(saveName, 'Save results as');
save([pathname filesep filename], 'spots');

saveName='spotsNet.mat';
[filename, pathname] = uiputfile(saveName, 'Save results as');
save([pathname filesep filename], 'Diff');

