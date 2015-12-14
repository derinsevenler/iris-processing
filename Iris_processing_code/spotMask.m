function [ mask ] = spotMask( image, radius, ycoord, xcoord )
%spotMask  creates a black and white image of spots.
%  

mask = zeros(size(image));

for i = 1:length(radius)
    mask = MidpointDisk(mask, radius(i),ycoord(i),xcoord(i),1);
end


end

