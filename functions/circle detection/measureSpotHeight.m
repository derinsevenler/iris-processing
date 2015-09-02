function [spotH, annH] = measureSpot(image, centroid, radiusMin, radiusMax)
% function [spotH, AnnH] = measureSpot(image, c, r)
% 
% image is the double array representing film thicknesses.
%
% radiusMin and radiusMax are the shortest and longest axes of the spot, presumably (X and Y, no rotation)
% centroid and radiusMin define the Spot region.
% The annulus is cropped between radiusMax and 
% centroid is in [r,c] convention, not x,y!

rs = radiusMin;
roInner = radiusMax;
roOuter = radiusMax+rs; % thinner for more oblong spots, thicker for more spherical spots. I have a hunch this will tend to improve the adaptability of ratio of their areas.

[rr, cc] = meshgrid(1:size(image,1), 1:size(image,2));

% circle mask
Rs = (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < rs^2;

% annulus mask
Ran = ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 > roInner^2 ) & ...
	  ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < roOuter^2 );

Rs = Rs';
Ran = Ran';
% get the average (median) value for each region
temp = image.*Ran;
Van = temp( temp ~= 0);
annH = median(Van);

temp = image.*Rs;
Vs = temp( temp ~= 0);
spotH = median(Vs);