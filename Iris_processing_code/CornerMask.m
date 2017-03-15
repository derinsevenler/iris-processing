function [ mask ] = CornerMask( image, gridx, gridy, cornerSize, columnsBlock, rowsBlock)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

mask = zeros(size(image));




gridx = gridx(:,all(~isnan(gridx))); %removes nan columns
gridy = gridy(:,all(~isnan(gridy))); %removes nan columns
gridx = gridx(~all(isnan(gridx),2),:); %removes nan rows
gridy = gridy(~all(isnan(gridy),2),:); %removes nan rows


xgaps = size(gridx,2)/columnsBlock -1;
ygaps = size(gridy,1)/rowsBlock - 1;

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

if xgaps >= 1;
for i = 1 : xgaps
    xEdges = [xEdges(1:columnsBlock*i) (xEdges(columnsBlock*i) + median(diffx)) xEdges(columnsBlock*i:end)];
    xEdges(columnsBlock*i+2+i) = xEdges(columnsBlock*i+3+i) - median(diffx);
end
end

if ygaps >= 1;
for i = 1 : ygaps
    yEdges = [yEdges(1:rowsBlock*i); (yEdges(rowsBlock*i) + median(diffy)); yEdges(rowsBlock*i:end)];
    yEdges(rowsBlock*i+2+i) = yEdges(rowsBlock*i+3+i) - median(diffy);
end
end

gridx = repmat(xEdges,length(yEdges),1);
gridy = repmat(yEdges,1,length(xEdges));
for i = 1 : size(gridx,1)
    for j = 1 : size(gridx,2)
        mask = MidpointDisk(mask, cornerSize,gridy(i,j), gridx(i,j), 1);
    end    
end


end

