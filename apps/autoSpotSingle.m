function [heights] = autoSpotSingle(raw,nCols,nRows,radius)
% function [heights] = autoSpotSingle(image,nCols,nRows,radius)
% 
% autoSpot is an interactive utility for automatically measuring the heights of a grid of spots. 
% 
% *Spots should not be within 1 radius from  any edge.
% *The grid is selected by clicking first on the upper-leftmost spot, 
% 	then on the lower-rightmost spot.
% *The grid of spot must be oriented along the image direction - No tilting
% *The spots must be roughly circular - they are found using 'imfindcircles'
% *The sizes of the 
% 
% 'image' is a previously measured array (i.e., )
% nCols and nRows are simply the number of columns, and rows, respectively
% 'heights' will have the same shape as the previous spots. 
% Spots are detected in columnwise batches. So, orient the image so that replicate spots are 
%  	in vertical columns to maximize performance.
% 'radius' is the nominal radius of the spots (in pixels) that you want to detect.

% filter it
disp('Removing squares, please wait...');
im = removeSiSquares(raw);


% ================================
% find the circles
% ================================
f = figure; imshow(im,[]);
title('Please click first on the upper-leftmost spot, then on the lower-rightmost spot');
[flX,flY] = ginput(2);
close(f);

sliceW = round((flY(2)-flY(1))/(nCols-1));
sliceH = round((flX(2)-flX(1))/(nCols-1)*nCols);

startRC = round([flY(1)-sliceW/2, flX(1)-sliceW/2]);

ff = 15;
sliceR = (startRC(1)-ff):(startRC(1)+ sliceH+ff);

r = [];
c = [];
for row = 1:nRows
	sliceC = (startRC(2)+(row-1)*sliceW-ff):(startRC(2)+row*sliceW+ff);
	slice = im(sliceR,sliceC);

	% screw with the slice to make sure the circles are visible enough
	m = median(slice(:));
	st = std(slice(:));
	slice(slice<m-3*st) = median(slice(:));

	[thisC,thisR] = imfindcircles(slice, [radius/1.5,radius*1.5]); % these parameters must be optimized

	c = [c; thisC+repmat([sliceC(1) sliceR(1)], length(thisC),1)];
	r = [r;thisR];
end

% show the circles
figure; imshow(im,[]);
viscircles(c,r);

res = input('Do the circles look ok? [Y]/n: ', 's');
if isempty(res)
	res = 'y';
end
if strcmp(lower(res), 'y')
	disp('ok great! Measuring heights...');
else
	return;
end

% Measure each circle
hts = zeros(length(c),1);
for n = 1:length(c)
	centroid = fliplr(c(n,:)); % now it is in (r,c)
	[spotH, annH] = measureSpotHeight(raw, centroid, r(n), r(n));
	hts(n) = spotH-annH;
end

% sort them into a grid
[~,xSort] = sort(c(:,1),'ascend');
cSortX = c(xSort,:);
hSortX = hts(xSort);

hGrid = zeros(nRows, nCols);
cGrid = zeros(nRows, nCols,2);

for m = 1:nCols
	idx = ((m-1)*nRows+1):m*nRows;
	thisC = cSortX(idx,:);
	thisH = hSortX(idx,:);
	[~,ySort] = sort(thisC(:,2),'ascend');
	cGrid(:,m,:) = thisC(ySort,:);
	hGrid(:,m) = thisH(ySort);
end

disp('Complete. Here are the heights:')
disp(hGrid)
heights = hGrid;

end