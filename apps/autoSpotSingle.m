% autoSpot is a more complex utility for measuring spot heights. 
% 
% Spots should not be within 1 radius from  any edge.
% Spots are found using imfindcircles, and fit to a grid.

% get the image
[fName, pName] = uigetfile('*.*', 'Select the results mat file:');
data = load([pName filesep fName]);
raw = data.results.heights;

% filter it
disp('Removing squares, please wait...');
im = removeSiSquares(raw);

% find the circles
[c,r] = imfindcircles(im, [10,30]); % these are hard-coded

% show the circles
figure; imshow(im,[]);
viscircles(c,r);

res = input('Do the circles look ok? [Y]/n: ', 's');
if isempty(res)
	res = 'y';
end
if strcmp(lower(res), 'y')
	disp('ok great!');
else
	return;
end

% Measure each circle
heights = zeros(length(c),1);
for n = 1:length(c)
	centroid = fliplr(c(n,:)); % now it is in (r,c)
	[spotH, annH] = measureSpotHeight(raw, centroid, r(n), r(n));
	heights(n) = spotH-annH;
end
hist(heights,30);