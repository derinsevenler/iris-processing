function nPMMA = PMMARefractiveIndexTemp(lambda, temperature)
% nPMMA = PMMARefractiveIndexTemp(temperature, lambda)
% 
% lambda is in microns
% temperature is the temperature in C, between 20 and 100. Assumes pressure is sea level.
%
% Parameters and equation from Kasarova et al. Temperature dependence of refractive characteristics of optical plastics, Journal of Physics 2010

Tref = 23; % celcius

% Load refractive index curve at 23C
RIs = load('/Users/derin/spectral reflectance/iris-processing/photonics/Refractive Indices/refractiveIndices.mat');
nRefSpectrum = RIs.nPMMA;

% temperature-dependent change
dndT = -1.32e-4;
deltaN = dndT*(temperature-Tref);

% reference n at this wavelength
nRef = interp1(nRefSpectrum(:,1), nRefSpectrum(:,2),lambda);

nPMMA = nRef+deltaN;