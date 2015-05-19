
% This is a version of simpleSpot.
% simpleSpot is a basic utility for measuring spot heights. Spots should not be within 1 radius from  any edge.

% get the lut image
lookupTable = load('goodLEDresults.mat');
ltIm = lookupTable.results.data_fitted;

mgrid = load('notSelfNormFitted234567.mat');
mgIm = mgrid.data_fitted;

% crop the spot region from both, and remove the Si squres;
[cropLT, rect] = imcrop(ltIm, median(ltIm(:))*[.8, 1.2]);
[cropMG] = imcrop(mgIm, rect);


% we want to modify the imgaes in exactly the same way for comparison, so removeSiSquares code is brought in and modified here.
im1 = cropLT;
im2 = cropMG;
% figure; imshow(im1, median(im1(:))*[.8, 1.2]);
% figure; imshow(im2, median(im2(:))*[.8, 1.2]);

zeroMask = (im1 == 0);
cropMask = imdilate(zeroMask, strel('disk',8));
% figure; imshow(cropMask);

% segment all of these regions
outLT = cropLT;
outMG = cropMG;
cc = bwconncomp(cropMask, 4);

for n = 1:cc.NumObjects
	t = false(size(zeroMask));
	t(cc.PixelIdxList{n}) = true;
	
	% measure the average value around this object
	bndry = logical(imdilate(t, strel('disk', 3))- t);
	

	bndryValsLT = im1(bndry);
	bndryValLT = mean(bndryValsLT(bndryValsLT~=0));
	bndryValsMG = im2(bndry);
	bndryValMG = mean(bndryValsMG(bndryValsMG~=0));

	% set the value within the object to that value
	outLT(t) = bndryValLT;
	outMG(t) = bndryValMG;
end
% figure; imshow(outLT, median(outLT(:))*[.8, 1.2]);
% figure; imshow(outMG, median(outMG(:))*[.8, 1.2]);






numSpots = 40;

for n = 1:numSpots
	figure;
	[spotR, spotRect] = imcrop(outLT, median(ltIm(:))*[.95, 1.1]);
	pause(0.05);
	close all;

	c = spotRect(1);
	r = spotRect(2);
	centroid = [r+spotRect(3)/2, c+spotRect(4)/2];
	rs = min(spotRect(3:4)/2);
	roInner = max(spotRect(3:4)/2);
	roOuter = roInner+rs; % thinner for more oblong spots, thicker for more spherical spots. I have a hunch this will tend to improve the adaptability of ratio of their areas.


	% crop the circle and an annulus
	[rr, cc] = meshgrid(1:size(outLT,1), 1:size(outLT,2));

	Rs = (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < rs^2;

	Ran = ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 > roInner^2 ) & ...
		  ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < roOuter^2 );

	Rs = Rs';
	Ran = Ran';
	% get the average value for each region for the lookup table
	temp = outLT.*Ran;
	Van = temp( temp ~= 0);
	% remove outliers
	Van(Van>3*std(Van))= median(Van);
	Dan = median(Van);

	temp = outLT.*Rs;
	Vs = temp( temp ~= 0);
	Vs(Vs>3*std(Vs))= median(Vs);
	Ds = median(Vs);

	h = Ds-Dan;
	disp([ 'LUT spot height is ' num2str(round(h*100)/100) ' nm.']);

	% get the average value for each region for MGrid
	temp = outMG.*Ran;
	Van = temp( temp ~= 0);
	Dan = median(Van);

	temp = outMG.*Rs;
	Vs = temp( temp ~= 0);
	Ds = median(Vs);

	h = Ds-Dan;
	disp([ 'MGrid Spot height is ' num2str(round(h*100)/100) ' nm.']);


	% % Show the regions

	% r1 = centroid(1) - (roOuter +5); % fudge factor
	% r2 = centroid(1) + (roOuter +5);
	% c1 = centroid(2) - (roOuter +5); % fudge factor
	% c2 = centroid(2) + (roOuter +5);

	% imReg = im(r1:r2,c1:c2);
	% h = figure;
	% imshow(imReg, median(imReg(:))*[.8, 1.2], 'InitialMagnification',500);

	% % draw a circle for the spot, and two for the annulus
	% th = 0:pi/50:2*pi;
	% % spot
	% xunit = rs * cos(th) + centroid(2)- c1;
	% yunit = rs * sin(th) + centroid(1)- r1;
	% hold on; plot(xunit, yunit, '-b');

	% %annulus
	% xunit = roInner * cos(th) + centroid(2)- c1;
	% yunit = roInner * sin(th) + centroid(1)- r1;
	% hold on; plot(xunit, yunit, '-r');
	% xunit = roOuter * cos(th) + centroid(2)- c1;
	% yunit = roOuter * sin(th) + centroid(1)- r1;
	% hold on; plot(xunit, yunit, '-r');

	% pause(3);
	% close(h);
end
