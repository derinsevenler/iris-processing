function [bestColor, LUT, X] = LUTgenerator(data, params)
% [d, bestColor, LUT, X] = LUTgenerator(data, Answer)
% 
% LUT is saved differently, depending on if you are considering a range of
% temperatures or not. If not, LUT is a two-column matrix where each row is
% (thickness, reflectance), easily plotted using 'plot(LUT)'.
% If you are considering a range of temperatures, LUT is a structure with
% fields LUT.T (array of temperatures), LUT.R (list of reflectances), and LUT.H
% LUT.H is a 2D array, easily visualized with 'surf(LUT.T, LUT.R, LUT.H)'.
% 
% This function replaces two previous functions, 'singleFrameLut' and 'noFitLUT'



% Get the average background film reflectances
f = figure('Name', 'Please select a region of film, near the spots:');
blue = data(:,:,1);
[blueC, RECT] = imcrop(blue, median(blue(:))*[.8 1.2]);
close(f);
pause(.01);
greenC = imcrop(squeeze(data(:,:,2)), RECT);
orangeC = imcrop(squeeze(data(:,:,3)), RECT);
redC = imcrop(squeeze(data(:,:,4)), RECT);
m = [mean(blueC(:)), mean(greenC(:)), mean(orangeC(:)), mean(redC(:))];

% =========================================================
% Fit the reflectance curve
% =========================================================
% Use the appropriate method (either accurate or relative) to fit
% Get the fit parameters (X): film thickness, offset and scaling coefficients
disp('Fitting background...');
xdata = {params.medium, params.film, params.temperature};
if strcmp(params.method, 'accurate');
	disp('Using accurate method.');
	% accurate method
	X = lsqcurvefit(@irisFun, [params.dApprox/1000 1 0], xdata, m); % dApprox converted to microns
else
	% relative method
	% we are using the helper function @relativeIrisFun instead of irisFun here
	disp('Using relative method.');
	xdata = [params.dApprox/1000, xdata]; % prepend with the given film thickness
	Xtemp = lsqcurvefit(@relativeIrisFun, [1 0], xdata, m);
	X = [xdata{1} Xtemp];
end

% =========================================================
% Generate the Look up table
% =========================================================
disp('Fitting complete. Generating LUT...');

if strcmp(params.useTemp,'Yes')
	disp('LUT is being generated over a range of temperatures:');
	temps = params.minTemp:5:params.maxTemp; % Intervals fixed to 5C, for now

	for t = 1:length(temps)
		thisLut = makeLUT(X, params.medium, params.film, temps(t), params.minus, params.plus, params.dt);
		LUT.H(t,:) = thisLUT(:,1)';
		disp(['Number ' num2str(t) ' of ' num2str(length(temps)) ' complete.']);
	end
	LUT.T = temps;
	LUT.R = thisLUT(:,2)';

else
	% LUT is the same old simple method
	[bestColor, LUT] = makeLUT(X, params.medium, params.film, params.temperature, params.minus, params.plus, params.dt);
	LUT(:,1) = LUT(:,1)*1000;
end

disp('Finished Generating LUT.')
end


% =========================================================
% Helper function for relative method
% =========================================================
function ydata = relativeIrisFun(x, xdata)
% relativeIrisFun is used with lsqcurvefit.
% xdata{1} is the prescribed film thickness. xdata{2} is the media.
% x is an array [A, B, C] of parameters for the fresnel equation. 
% This function is basically the same as 'measure4LED', but formatted to work with lsqcurvefit.
% This function is in microns!!

[d, medium, film, temperature] = xdata{:};

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
	R = calcReflectance(d, lambda, medium, film, temperature)';
	mirSig = ((rSi.*s).^2);
	reflectionSpectra = (R.*s).^2; % Reflection intensity
	I = sum(reflectionSpectra)./sum(mirSig);
	ydata(z) = I*x(1) + x(2);
end
end
