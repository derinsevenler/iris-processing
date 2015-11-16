function ydata = irisFun(x, xdata)
% irisFun is to be used with lsqcurvefit.
% xdata contains detection parameters. ydata is the led intensity.
% x is an array [A, B, C] of parameters for the fresnel equation. 
% This function is basically the same as 'measure4LED', but formatted to work with lsqcurvefit.
% This function is in microns!!

[medium, film, temperature] = xdata{:}; % This isn't how xdata is supposed to be used, no big deal.

lambda = (.4:.001:.65)';

n = load('refractiveIndices.mat');

% LED spectrum of this LED (xdata)
% ledF = load('ledSpectraArray.mat'); % measured at Koc university
ledF = load('iris1LEDSpectra.mat'); % extracted from MGrid code
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
	d = x(1); % first parameter
	R = calcReflectance(d, lambda, medium, film, temperature)';
	mirSig = ((rSi.*s).^2);
	reflectionSpectra = (R.*s).^2; % Reflection intensity
	I = sum(reflectionSpectra)./sum(mirSig);
	ydata(z) = I*x(2) + x(3);
end
