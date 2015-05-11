function R = calcReflectance(d, lambda, media)
% calculate and return the reflectance spectrum R 
% for a given film height over the wavelength range 
% lambda (microns). R is unitless, the ratio of the 
% reflected to incident E-field strength.

theta = 0; % angle of incidence
nOx = 1.45; % constant for now

if strcmp(media, 'air')
	nMedia = 1; % constant for now
elseif strcmp(media, 'water')
	nMedia = 1.33;
else 
	nMedia = media; % you can put in a number.
end

ns = load('refractiveIndices.mat');
nSi = ns.nSi;
nSiO2 = ns.nSiO2;

R = [];
for n = 1:length(lambda)
	nSi_l = interp1(nSi(:,1), nSi(:,2), lambda(n));
	nSiO2_l = interp1(nSi(:,1), nSi(:,2), lambda(n));

	nVec = [nMedia, nOx, nSi_l];
	[r123, t123] = fres2(nVec, d, theta, lambda(n)); % r123 is the reflection coefficient, a *complex amplitude*.
	R(n) = abs(r123); % R is the magnitude of the reflection coefficient - corresponding with the electric field strength.
end

end