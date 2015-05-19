% convert micro-manager tiff stack to Zoiray-format .mat files
% This works only for TIF stacks that are in the order *blue, green,
% orange, red*

% ** This is only tested with images from IRIS1, in PHO 714 **

% You an use this if you want to use MGrid but acquired the images with micro-manager.

%% Load the images 

% Get the measurement image file info
[imfile, imfolder] = uigetfile('*.*', 'Select the TIFF image stack (multicolor)');
tifFile= [imfolder filesep imfile];

% Get the mirror image file info
[mirFile, mirFolder] = uigetfile('*.*', 'Select the mirror file (TIFF image stack also)');
mirFile= [mirFolder filesep mirFile];


% % load the first image to get the self-reference region
% f = figure('Name', 'Please select a region of bare Si');
% im = double(imread(tifFile, 1));
% [~, selfRefRegion] = imcrop(im, median(im(:))*[.8 1.2]);
% pause(0.01); % so the window can close
% close(f);

% Load the images. Normalize by the mirrors, NOT self-reference region though
temp = imread(tifFile, 1);
data = zeros(4, size(temp,1), size(temp,2));
for channel = 1:4
	I = imread(tifFile, channel);
	mir = imread(mirFile, channel);
	In = double(I)./double(mir);
	% sRef = imcrop(In, selfRefRegion);
	data(channel,:,:) = In; %./median(sRef(:));
end

%% resave the images with all the other things needed for MGrid.
data_date = datestr(now);
data_pd = [1; 1; 1; 1];
data_raw = data;
data_ref = [.9653; .9602; .9576; .9657];
data_wav = [455 518 598 635];
iris_info.version = 4;
iris_info.instr = 'IRIS1';

saveName = [datestr(now, 'HHMMSS') 'ConvertedDataSet.mat'];
[filename, pathname] = uiputfile(saveName, 'Save results as');
save([pathname filesep filename], 'data', 'data_wav', 'data_date', 'data_pd', 'data_raw', 'data_ref', 'data_wav', 'iris_info');