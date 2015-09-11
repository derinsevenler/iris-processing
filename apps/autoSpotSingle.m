% function [heights] = autoSpotSingle(raw,nCols,nRows,radius)
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
title('Please click the first spot in each column, then the last spot in the first column');
[flX,flY] = ginput(nCols+1);
% close(f);

deltaRC = [flY(end)-flY(1), flX(end)-flX(1)]/(nRows-1);

% get grid positions
cR = zeros(nRows, nCols);
cC = zeros(nRows, nCols);
for n = 1:nRows
	for m = 1:nCols
		cR(n,m) = round(flY(m)+(n-1)*deltaRC(1));
		cC(n,m) = round(flX(m)+(n-1)*deltaRC(2));
	end
end
hold on;
plot(cC,cR,'*');

% find circles at each grid position
c = [];
r = [];
regionHW = radius*3;
for m = 1:nCols
	for n = 1:nRows
		% disp(['Spot ' num2str(n) ' ' num2str(m) ':'])
		spotRegion = im( (cR(n,m)-regionHW):(cR(n,m)+regionHW) , (cC(n,m)-regionHW):(cC(n,m)+regionHW) );

		thFactor = 5;
		thisC = [];
		while isempty(thisC)
			% iteratively lower threshold until you can see the particle
			th = median(spotRegion(:))-thFactor*std(spotRegion(:));
			spotRegion(spotRegion<95)=median(spotRegion(:));
			[thisC,thisR] = imfindcircles(spotRegion, round([radius/1.5,radius*1.5]));
			thFactor = thFactor*.9;
		end
		
		thisC + [cR(n,m), cC(n,m)] - regionHW;
		c = [c; fliplr(thisC) + [cR(n,m), cC(n,m)] - regionHW];
		r = [r; thisR];
	end
end
c = fliplr(c);

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

hGrid = reshape(hts,nRows,nCols);

disp('Complete. Here are the heights:')
disp(hGrid)

