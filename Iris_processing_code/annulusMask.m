function [ mask ] = annulusMask( image, radius, ycoord, xcoord, percentage )
%spotMask  creates a black and white image of spots.
%  it will create it the size of image.  Each spot will have the radius of
%  radius*percentage at the xcoord,ycoord.

mask = zeros(size(image));

for i = 1:length(radius)
    mask = MidpointDisk(mask, (percentage+0.1)*radius(i),ycoord(i),xcoord(i), 1);
    mask = MidpointDisk(mask, (percentage-0.1)*radius(i),ycoord(i),xcoord(i), 0);
end



end

