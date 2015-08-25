function R = calcReflectance(d, lambda, varargin)
% R = calcReflectance(d, lambda, [media, film, temperature])
% 
% Calcualtes the reflectance spectrum R 
% for a film of thickness 'd' over the wavelength range 
% 'lambda' (microns). R is unitless, the ratio of the 
% reflected to incident E-field strength.
% 
% Parameters 'd', 'lambda' are required.
% Optional parameters:
% 
% 'media': It works with an immersion media of either air or pure water.
% 		The default is 'air', otherwise provide 'water'. 
% 'film': It works with films of either pure amorphous SiO2, or microchem 
% 		PMMA 495. The default is 'SiO2', otherwise provide 'PMMA'.
% 
% 'temperature': If measuring reflectance in water, the temperature may be provided.
% 		The default is 20 (numeric, in celcius).
%
% As always, if you want to provide the optional parameter 'temperature', you need to 
% also provide 'media' and 'film' first.

% parse inputs
numVarArgs = length(varargin);
if numVarArgs > 3
	error('You have too many arguments.');
end
optArgs = {'air', 'SiO2',20};
optArgs(1:numVarArgs) = varargin;
[media, film, temperature] = optArgs{:};


theta = 0; % angle of incidence

R = [];
for n = 1:length(lambda)

	% =================================
	% Get the media refractive index
	% =================================
	% it's approximated by the real part only

	if strcmp(media, 'air')
		nMedia = 1; % constant 
	elseif strcmp(media, 'water')
		% use temperature equation
		nMedia = waterRefractiveIndexTemp(lambda(n), temperature);
	end

	% ================================
	% Get the film refractive index
	% ================================
	% it's approximated by the real part only
	if strcmp(film, 'SiO2')
		nFilm = SiO2RefractiveIndexTemp(lambda(n), temperature);
	elseif strcmp(film, 'PMMA')
		nFilm = PMMARefractiveIndexTemp(lambda(n), temperature);
	end

	% ================================
	% Get the substrate (Si) refractive index
	% ================================
	% it's approximated by the real part only

	nSubstrate = SiRefractiveIndexTemp(lambda(n), temperature);

	% Calculate the reflection coefficient using fresnel equation
	nVec = [nMedia, nFilm, nSubstrate];
	[r123, t123] = fres2(nVec, d, theta, lambda(n)); % r123 is the reflection coefficient, a *complex amplitude*.
	R(n) = abs(r123); % R is the magnitude of the reflection coefficient - corresponding with the electric field strength.
end

end