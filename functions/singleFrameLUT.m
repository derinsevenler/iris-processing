function [d, bestColor, LUT, X] = singleFrameLUT(data, media, dApprox, minus, plus, dt)
% data is the image you want to fit. 
% media is the emersion media (i.e., 'air', 'water', 1.34, etc.)
% dApprox is the nominal SiO2 thickness, in nanometers.

% first, get the average background values of the images

fbk = figure('Name', 'Please select a region of SiO2');
blue = data(:,:,1);
[blueC RECT] = imcrop(blue, median(blue(:))*[.8 1.2]);
pause(0.1); % so the window can close
close(fbk);
pause(0.1);
greenC = imcrop(data(:,:,2), RECT);
orangeC = imcrop(data(:,:,3), RECT);
redC = imcrop(data(:,:,4), RECT);
m = [mean(blueC(:)), mean(greenC(:)), mean(orangeC(:)), mean(redC(:))];

% Then, fit those values with lsqcurvefit
disp('Fitting background...');
X = lsqcurvefit(@irisFun, [dApprox/1000 1 0], media, m); % dApprox converted to microns

% Generate a 1-color LUT with the fitted values
disp('generating LUT...');
[bestColor, LUT] = generateSimpleLUT(X, media, minus, plus, dt);
% use the LUT to get the approximate heights
disp('Interpolating...');
% convert the LUT from microns to nm
LUT(:,1) = LUT(:,1)*1000;
bestImg = squeeze(data(bestColor,:,:));

d = interp1(LUT(:,2), LUT(:,1), bestImg, 'nearest', 0); % use nearest neighbor interpolation, extrapolation value 0
disp('Finished!');
end