% useLUTsingle

% Use a lookup table that you've generated with 'generateLUT.m' to fit another image. If you haven't generated a lookup table yet, this function isn't for you.

% Get the measurement image file info
[file, folder] = uigetfile('*.*', 'Select the TIFF image stack (multicolor)');
tifFile= [folder filesep file];

% Get the mirror image file info
[file, folder] = uigetfile('*.*', 'Select the mirror file (TIFF image stack also)');
mirFile= [folder filesep file];

% load the first image to get the self-reference region
f = figure('Name', 'Please select a region of bare Si');
im = imread(tifFile, 1);
[~, selfRefRegion] = imcrop(im, median(double(im(:)))*[.8 1.2]);
pause(0.01); % so the window can close
close(f);

% Load the images. Normalize by the mirrors and self-reference regions
data = zeros(size(im,1), size(im,2), 4);
for channel = 1:4
	I = imread(tifFile, channel);
	mir = imread(mirFile, channel);
	In = double(I)./double(mir);
	sRef = imcrop(In, selfRefRegion);
	data(:,:,channel) = In./median(sRef(:));
end

% load the lookup table
[lutFile, lutFolder] = uigetfile('*.mat', 'Select the results file with the lookup table you wish to use');

lutF = load([lutFolder filesep lutFile]);
