function outI = removeSiSquares(im)
% input a fitted image, and the output image won't have any bare Si squares.
% select the region with spots. This only works with images that were fit with the LUT - they are set to 

% find all regions with zeros, and make a mask around them.
zeroMask = (im == 0);
cropMask = imdilate(zeroMask, strel('disk',6));
% figure; imshow(cropMask);

% segment all of these regions
outI = im;
cc = bwconncomp(cropMask, 4);

for n = 1:cc.NumObjects
	t = false(size(zeroMask));
	t(cc.PixelIdxList{n}) = true;
	
	% measure the average value around this object
	bndry = logical(imdilate(t, strel('disk', 3))- t);
	bndryVals = im(bndry);
	bndryVal = mean(bndryVals(bndryVals~=0));
	
	% set the value within the object to that value
	outI(t) = bndryVal;
end
% figure; imshow(outI, median(outI(:))*[.8, 1.2]);

