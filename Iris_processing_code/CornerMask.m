function [ mask ] = CornerMask( image, gridx, gridy )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

mask = zeros(size(image));

cornerSize = 10;

indx = find(isnan(gridx));
indy = find(isnan(gridy));
gridx(indx) = [];
gridy(indy) = [];

row = size(gridx,1);
col = size(gridx,2);

xCenters = gridx(1,:);
yCenters = gridy(:,1);

diffx = diff(xCenters);
diffy = diff(yCenters);

xEdges = ones(1 , length(xCenters)+1);
yEdges = ones(length(yCenters)+1, 1);

xEdges(1) = xCenters(1) - diffx(1)/2;
yEdges(1) = yCenters(1) - diffy(1)/2;

xEdges(2:end-1) = xCenters(1:end-1) + diffx/2;
yEdges(2:end-1) = yCenters(1:end-1) + diffy/2;

xEdges(end) = xCenters(end) + diffx(end)/2;
yEdges(end) = yCenters(end) + diffy(end)/2;

gridx = repmat(xEdges,row+1,1);
gridy = repmat(yEdges,1,col+1);
for i = 1 : size(gridx,1)
    for j = 1 : size(gridx,2)
        mask = MidpointDisk(mask, cornerSize,gridy(i,j), gridx(i,j), 1);
    end    
end


end

