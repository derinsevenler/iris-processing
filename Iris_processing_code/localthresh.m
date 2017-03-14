function [ binary ] = localthresh( spotad )
%localthresh finds the rows and columns of each spot, then calculates the thresholded image based on local thresholds around each spot
%   First, the function determines the rows and columns of each spot. Then,
%   it forms a grid around each spot, and calculates the local threshold
%   for each grid element, stitching the full binary image stitch by
%   stitch.

%grid the FOV and find the xCenters and yCenters of each grid
[ xCenters, yCenters, ~ ] = Gridding( spotad );


%split the image into ROIs with 1 spot per ROI based on the spot centers
%found above
%x divisions
diff_x = diff(xCenters);
x = ones(length(xCenters)+1,1);
x(2:end-1) = xCenters(1:end-1) + diff_x/2;
x(end) = size(spotad,2);
x = round(x);

%Y divisions
diff_y = diff(yCenters);
y = ones(length(yCenters)+1, 1);
y(2:end-1) = yCenters(1:end-1) + diff_y/2;
y(end) = size(spotad,1);
y = round(y);

%Calculate threshold of image ROI by ROI such that low signal spots are
%included.
for i = 1:length(y)-1
    for j = 1:length(x)-1
        level = graythresh(spotad(y(i):y(i+1),x(j):x(j+1)));
        binary(y(i):y(i+1),x(j):x(j+1)) = im2bw(spotad(y(i):y(i+1),x(j):x(j+1)),level);
    end
end



end

