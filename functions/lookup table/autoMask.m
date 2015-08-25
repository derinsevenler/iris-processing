function vals = autoMask(data)
% vals = autoMask(data)
% 
% Automatic measurement of the average background SiO2 brightness across the image
% data is a (r x c x n) *double* array of the n different channel images
% vals is an array length n, of the average background reflectances
% 
% This is designed to work with images with Si regions in them. It might not work
% if there aren't any significant Si regions.
% 
% **This function is not finished yet**

% Create a mask using the blue channel
blue = data(:,:,1);
[n, x] = hist(blue(:), 100);

% get the two largest peaks (i.e., the mode Si and mode SiO2)
[pks, locs] = findpeaks(n,'sortstr', 'descend', 'npeaks', 2);
v = x(locs);
modeSi = max(v); % i.e., the peak of brighter values
modeSiO2 = min(v); % i.e., the other peak of darker values

% make a mask for Si region
% This binarization uses the midpoint (average value) between the two peaks (modes) in the blue channel. Otsu's method might be slightly better, or might make no difference.
SiMask = ( blue > (modeSi + modeSiO2)/2 );

% make a mask for SiO2 region
SiO2Mask = ~SiMask;

% Average the whole damn thing???