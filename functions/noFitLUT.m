function [d, bestColor, LUT, X] = noFitLUT(data, media, dGiven, minus, plus, dt)
% This script generates LUT for thin films, which are too thin to have any visible-spectrum fringes and therefore cannot be fit normally.
% Here, we prescribe the baseline thickness with dGiven, rather than fit it accurately.

% first, get the average background values of the images
h = figure;
blue = squeeze(data(:,:,1));
[blueC, RECT] = imcrop(blue, median(blue(:))*[.8 1.2]);
close(h);
pause(.01);
greenC = imcrop(squeeze(data(:,:,2)), RECT);
orangeC = imcrop(squeeze(data(:,:,3)), RECT);
redC = imcrop(squeeze(data(:,:,4)), RECT);
m = [mean(blueC(:)), mean(greenC(:)), mean(orangeC(:)), mean(redC(:))];

% Then, fit those values with lsqcurvefit
disp('Fitting to the given background height...');
xdata = {dGiven/1000, media}; % dGiven converted to microns
X = lsqcurvefit(@fitParams, [1 0], xdata, m);

disp('generating LUT...');
lutX = [xdata{1} X];
[bestColor, LUT] = generateSimpleLUT(lutX, media, minus, plus, dt);
% use the LUT to get the approximate heights
disp('Interpolating...');
% convert the LUT from microns to nm
LUT(:,1) = LUT(:,1)*1000;
bestImg = squeeze(data(:,:,bestColor));

d = interp1(LUT(:,2), LUT(:,1), bestImg, 'nearest', 0); % use nearest neighbor interpolation, extrapolation value 0
disp('Finished!');
end


function ydata = fitParams(x, xdata)
% fitParams is to be used with lsqcurvefit.
% xdata{1} is the prescribed film thickness. xdata{2} is the media.
% x is an array [A, B, C] of parameters for the fresnel equation. 
% This function is basically the same as 'measure4LED', but formatted to work with lsqcurvefit.
% This is only for air right now.
% This function is in microns!!

d = xdata{1};
media = xdata{2}; % This isn't how xdata is supposed to be used, no big deal.

lambda = (.4:.001:.65)';

n = load('refractiveIndices.mat');

% LED spectrum of this LED (xdata)
% ledF = load('ledSpectraArray.mat');
ledF = load('iris1LEDSpectra.mat');
ledSpectra=ledF.spectra;

% Normalize by Si mirror reflectivity in air
nSi_l = interp1(n.nSi(:,1), n.nSi(:,2), lambda);
[rSi, ~] = fres1(1.0, nSi_l, 0);

for z = 1:4
	% darkS = interp1(ledSpectra{5}(:,1)*.001, ledSpectra{5}(:,2), lambda); % ledSpectra wavelength is in nm!
	s = interp1(ledSpectra{z}(:,1), ledSpectra{z}(:,2), lambda);
	% s = s- darkS; % remove dark signal from the photodetector used to make the measurements
	
	s(s<0) = 0; % remove negative numbers
	s = sqrt(s); % get s in E-field magnitude rather than intensity

	% Reflectance at this thickness (x)
	R = calcReflectance(d, lambda, media)';
	mirSig = ((rSi.*s).^2);
	reflectionSpectra = (R.*s).^2; % Reflection intensity
	I = sum(reflectionSpectra)./sum(mirSig);
	ydata(z) = I*x(1) + x(2);
end
end
