% GenerateLUT.m
% 11 May 2015, Derin Sevenler

% This script walks you through generating a lookup table for IRIS image processing.
% This script is only configured to work with TIFF stacks collected using micromanager, 
% saved in the order (blue, green, orange red). Use only a single image (not a time series)
% with this function.

warning('off','images:initSize:adjustingMag');

%% Get fit parameters
[p, Cancelled] = getLUTparams();
if Cancelled
	disp('Goodbye');
	return;
end

%% Load the images

% Get the measurement image file info
[imfile, imfolder] = uigetfile('*.*', 'Select the TIFF image stack (multicolor)');
tifFile= [imfolder filesep imfile];

% % Get the mirror image file info
% [mirFile, mirFolder] = uigetfile('*.*', 'Select the mirror file (TIFF image stack also)');
% mirFile= [mirFolder filesep mirFile];

% load the first image to get the self-reference region
f = figure('Name', 'Please select a region of bare Si:');
im = double(imread(tifFile, 1));
[~, selfRefRegion] = imcrop(im, median(im(:))*[.8 1.2]);
pause(0.01); % so the window can close
close(f);

% Load the images. Normalize by the mirrors and self-reference regions

data = zeros(size(im,1), size(im,2), 4);
for channel = 1:4
	I = imread(tifFile, channel);
	% mir = imread(mirFile, channel);
	% In = double(I)./double(mir);
	sRef = imcrop(I, selfRefRegion);
	data(:,:,channel) = I./median(sRef(:));
end

%% Generate the look up table.
[bestColor, LUT, X] = LUTgenerator(data, p);

% Save the LUT and the Parameters
results.LUT = LUT;
results.bestColor = bestColor;

params.dGiven = p.dApprox;
params.plus = p.plus;
params.minus = p.minus;
params.dt = p.dt;
params.medium = p.medium;
params.film = p.film;
params.temperature = p.temperature;
params.origFile = tifFile;

% Additional parameters for temperature-dependent LUTs
if strcmp(p.useTemp, 'Yes')
	% TODO: Interpolate an LUT for this image which is at the right temperature
	thisLUT(:,1) = LUT.reflectances
	% TODO: Use the interpolated LUT to save 'heights'
	results.heights = interp1(thisLUT(:,2), thisLUT(:,1), squeeze(data(:,:,bestColor)), 'linear', 0);
else
	results.heights = interp1(LUT(:,2), LUT(:,1), squeeze(data(:,:,bestColor)), 'linear', 0);
	figure; imshow(results.heights,[p.dApprox-p.minus p.dApprox+p.plus]);
end
saveName = [datestr(now, 'HHMMSS') 'results.mat'];
[filename, pathname] = uiputfile(saveName, 'Save results as');
save([pathname filesep filename], 'results', 'params');