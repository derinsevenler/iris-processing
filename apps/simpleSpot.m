% simpleSpot is a basic utility for measuring spot heights. Spots should not be within 1 radius from  any edge.

% get the image
f = uigetfile('*.*', 'Select the results mat file:');
data = load(f);
im = data.results.data_fitted;

[spotR, spotRect] = imcrop(im,median(im(:))*[.8, 1.2], 'Select a close crop of the spot');
pause(0.05);
close(h);

r = spotRect(1);
c = spotRect(2);
centroid = [r-spotRect(3), c-spotRect(4)];
rs = min(spotRect(3:4));
roInner = max(spotRect(3:4));
roOuter = roInner+rs; % thinner for more oblong psots, thicker for more spherical spots. I have a hunch this will tend to improve the adaptability of ratio of their areas.

[x, y] = meshgrid(1:size(im,1), 1:size(im,2));
Rs = zeros(size(im));


% Identify a background region, from 1.5r to 2r


% calculate the average height above the background

% Draw circles for the two regions