% simpleSpot is a basic utility for measuring spot heights. Spots should not be within 1 radius from  any edge.

% get the image
f = uigetfile('*.*', 'Select the results mat file:');
data = load(f);
im = data.results.data_fitted;

[spotR, spotRect] = imcrop(im,median(im(:))*[.8, 1.2]);
pause(0.05);
close;

c = spotRect(1);
r = spotRect(2);
centroid = [r+spotRect(3)/2, c+spotRect(4)/2];
rs = min(spotRect(3:4)/2);
roInner = max(spotRect(3:4)/2);
roOuter = roInner+rs; % thinner for more oblong spots, thicker for more spherical spots. I have a hunch this will tend to improve the adaptability of ratio of their areas.


% crop the circle and an annulus
[rr, cc] = meshgrid(1:size(im,1), 1:size(im,2));

Rs = (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < rs^2;

Ran = ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 > roInner^2 ) & ...
	  ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < roOuter^2 );

Rs = Rs';
Ran = Ran';
% get the average value for each region
Aan = sum(Ran);



% Draw circles for the two regions